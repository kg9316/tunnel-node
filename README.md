# tunnel-node

This repository packages the tunnel node setup exported from the running server and turns it into a repeatable deployment.
Pinggy clone :-)

## What it includes
- OpenSSH tunnel endpoint on ports 22 and 443
- tunnel registry builder
- registry landing page
- device admin page
- nginx reverse proxy configuration
- UFW baseline rules
- hardening notes for admin SSH

## Current architecture
- Devices connect to the `tunnel` user over SSH on port 443.
- SSH reverse forwards create a dynamic remote tunnel port.
- `tunnel-registry.py` maps SSH sessions to device names based on `authorized_keys` comments.
- `tunnel-registry-http.py` exposes a landing page and API on localhost, intended to sit behind nginx.
- `tunnel-admin.py` manages devices and generates RSA 2048 PEM keys.

## Current scaling reality
This repo reflects the exported server state. It does **not** yet include the next-generation shared relay daemon. With the current layout, start with a modest device count, validate behaviour, and scale carefully.

## Quick start
```bash
curl -s https://raw.githubusercontent.com/kg9316/tunnel-node/main/install.sh | sudo bash
```

## After install
Create a password file for nginx:
```bash
sudo htpasswd -c /etc/nginx/.htpasswd_tunnel_registry admin
sudo systemctl reload nginx
```

## Web paths
- `/` registry landing page
- `/api/tunnels` registry JSON
- `/admin/devices/` device admin

## SSH hardening
Read `docs/SSH-HARDENING.md` before disabling password authentication for admins.

## Future work
- replace per-device relay helpers with a single relay daemon
- add multi-node scheduling / control-plane
- add stronger admin auth and audit trails
