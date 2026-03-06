#!/usr/bin/env python3
import subprocess
import re
import json
from pathlib import Path
from datetime import datetime, timezone

AUTHORIZED_KEYS = "/home/tunnel/.ssh/authorized_keys"
OUTPUT_JSON = "/var/lib/tunnel-registry/active-tunnels.json"


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=False).stdout


def get_authorized_key_comments():
    comments = {}
    with open(AUTHORIZED_KEYS, "r", encoding="utf-8") as f:
        for i, line in enumerate(f, start=1):
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            parts = s.split()
            if len(parts) >= 3:
                comments[i] = parts[-1]
            else:
                comments[i] = f"line-{i}"
    return comments


def get_tunnel_processes():
    out = run(["ps", "-eo", "pid=,ppid=,user=,args="])
    priv = {}
    user_procs = {}

    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue

        parts = line.split(None, 3)
        if len(parts) < 4:
            continue

        pid_s, ppid_s, user, args = parts

        try:
            pid = int(pid_s)
            ppid = int(ppid_s)
        except ValueError:
            continue

        if args == "sshd: tunnel [priv]":
            priv[pid] = {"pid": pid, "ppid": ppid, "user": user, "args": args}
        elif args == "sshd: tunnel":
            user_procs[pid] = {"pid": pid, "ppid": ppid, "user": user, "args": args}

    return priv, user_procs

def get_listen_ports_for_pid(pid):
    out = run(["ss", "-tlnp"])
    ports = []
    for line in out.splitlines():
        if f'pid={pid},' not in line:
            continue
        if "LISTEN" not in line:
            continue

        parts = line.split()
        if len(parts) < 4:
            continue

        local_addr = parts[3]
        m = re.search(r":(\d+)$", local_addr)
        if not m:
            continue

        port = int(m.group(1))
        if port not in (22, 443):
            ports.append(port)

    return sorted(set(ports))


def parse_journal():
    out = run(["journalctl", "-u", "ssh", "--no-pager", "-o", "short-iso"])
    entries = {}

    for line in out.splitlines():
        m = re.search(r"sshd\[(\d+)\]: (.*)$", line)
        if not m:
            continue

        pid = int(m.group(1))
        msg = m.group(2)

        if pid not in entries:
            entries[pid] = {
                "session_pid": pid,
                "client_ip": None,
                "key_fingerprint": None,
                "authorized_keys_line": None,
                "connected_at": None,
            }

        e = entries[pid]

        if e["connected_at"] is None:
            ts = line[:19]
            e["connected_at"] = ts

        if "Accepted key" in msg and "authorized_keys:" in msg:
            m2 = re.search(r"Accepted key \S+ (SHA256:[A-Za-z0-9+/=_-]+) found at .+authorized_keys:(\d+)", msg)
            if m2:
                e["key_fingerprint"] = m2.group(1)
                e["authorized_keys_line"] = int(m2.group(2))

        if "Accepted publickey for tunnel from" in msg:
            m3 = re.search(r"Accepted publickey for tunnel from (\S+) port \d+ ssh2: \S+ (SHA256:[A-Za-z0-9+/=_-]+)", msg)
            if m3:
                e["client_ip"] = m3.group(1)
                e["key_fingerprint"] = m3.group(2)

    return entries


def build_registry():
    comments = get_authorized_key_comments()
    priv_procs, user_procs = get_tunnel_processes()
    journal = parse_journal()

    result = []

    for priv_pid, priv_info in priv_procs.items():
        user_proc = None
        for upid, uinfo in user_procs.items():
            if uinfo["ppid"] == priv_pid:
                user_proc = uinfo
                break

        if not user_proc:
            continue

        ports = get_listen_ports_for_pid(user_proc["pid"])
        if not ports:
            continue

        j = journal.get(priv_pid, {})
        line_no = j.get("authorized_keys_line")
        device_name = comments.get(line_no, f"unknown-line-{line_no}") if line_no else "unknown"

        result.append({
            "device": device_name,
            "clientIp": j.get("client_ip"),
            "fingerprint": j.get("key_fingerprint"),
            "authorizedKeysLine": line_no,
            "sessionPid": priv_pid,
            "userPid": user_proc["pid"],
            "ports": ports,
            "connectedAt": j.get("connected_at"),
            "updatedAt": datetime.now(timezone.utc).isoformat()
        })

    return result


def main():
    data = build_registry()
    out_path = Path(OUTPUT_JSON)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
