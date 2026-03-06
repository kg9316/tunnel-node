#!/usr/bin/env python3
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

ACTIVE_TUNNELS_FILE = Path("/var/lib/tunnel-registry/active-tunnels.json")
DEVICES_FILE = Path("/var/lib/tunnel-registry/devices.json")
RELAY_STATE_FILE = Path("/var/lib/tunnel-registry/relay-state.json")

HOST = "127.0.0.1"
PORT = 8080


def load_json(path: Path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def pid_alive(pid):
    if not pid:
        return False
    try:
        os.kill(int(pid), 0)
        return True
    except OSError:
        return False


def build_combined_data():
    active = load_json(ACTIVE_TUNNELS_FILE, [])
    devices = load_json(DEVICES_FILE, [])
    relay_state = load_json(RELAY_STATE_FILE, {})

    devices_by_name = {}
    for d in devices:
        name = d.get("device")
        if name:
            devices_by_name[name] = d

    active_by_name = {}
    for item in active:
        device = item.get("device")
        if device:
            active_by_name[device] = item

    result = []
    all_names = sorted(set(devices_by_name.keys()) | set(active_by_name.keys()))

    for device in all_names:
        cfg = devices_by_name.get(device, {})
        act = active_by_name.get(device, {})
        relay = relay_state.get(device, {})

        ports = act.get("ports") or []
        remote_port = ports[0] if ports else None
        mapped_port = cfg.get("publicPort")
        relay_pid = relay.get("pid")
        relay_alive = pid_alive(relay_pid)
        relay_tunnel_port = relay.get("tunnelPort")
        relay_public_port = relay.get("publicPort")

        result.append({
            "device": device,
            "online": bool(act),
            "clientIp": act.get("clientIp", ""),
            "remoteTunnelPort": remote_port,
            "mappedPublicPort": mapped_port,
            "relayPid": relay_pid,
            "relayActive": relay_alive,
            "relayTunnelPort": relay_tunnel_port,
            "relayPublicPort": relay_public_port,
            "connectedAt": act.get("connectedAt", ""),
            "updatedAt": act.get("updatedAt", ""),
            "fingerprint": act.get("fingerprint", ""),
        })

    return result


def html_page(data):
    rows = []
    for item in data:
        rows.append(
            f"""
            <tr>
              <td>{item.get("device","")}</td>
              <td>{"ONLINE" if item.get("online") else "OFFLINE"}</td>
              <td>{item.get("clientIp","") or "-"}</td>
              <td>{item.get("remoteTunnelPort") if item.get("remoteTunnelPort") is not None else "-"}</td>
              <td>{item.get("mappedPublicPort") if item.get("mappedPublicPort") is not None else "-"}</td>
              <td>{"YES" if item.get("relayActive") else "NO"}</td>
              <td>{item.get("relayPid") if item.get("relayPid") is not None else "-"}</td>
              <td>{item.get("relayTunnelPort") if item.get("relayTunnelPort") is not None else "-"}</td>
              <td>{item.get("connectedAt","") or "-"}</td>
              <td>{item.get("updatedAt","") or "-"}</td>
            </tr>
            """
        )

    rows_html = "\n".join(rows) if rows else '<tr><td colspan="10">No devices</td></tr>'

    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Tunnel Registry</title>
  <style>
    body {{
      font-family: Arial, sans-serif;
      margin: 24px;
      background: #f7f7f7;
      color: #222;
    }}
    table {{
      border-collapse: collapse;
      width: 100%;
      background: white;
    }}
    th, td {{
      border: 1px solid #ddd;
      padding: 8px 10px;
      text-align: left;
      vertical-align: top;
    }}
    th {{
      background: #efefef;
    }}
  </style>
</head>
<body>
  <h1>Tunnel Registry</h1>
  <table>
    <thead>
      <tr>
        <th>Device</th>
        <th>Status</th>
        <th>Client IP</th>
        <th>Remote tunnel port</th>
        <th>Mapped public port</th>
        <th>Relay active</th>
        <th>Relay PID</th>
        <th>Relay tunnel port</th>
        <th>Connected</th>
        <th>Updated</th>
      </tr>
    </thead>
    <tbody>
      {rows_html}
    </tbody>
  </table>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        data = build_combined_data()

        if self.path in ("/", "/index.html"):
            body = html_page(data).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path == "/api/tunnels":
            body = json.dumps(data, indent=2).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_response(404)
        self.end_headers()
        self.wfile.write(b"Not found")

    def log_message(self, format, *args):
        return


def main():
    server = HTTPServer((HOST, PORT), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
