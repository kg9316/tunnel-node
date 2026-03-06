# Deploy a new tunnel node

1. Provision a fresh Ubuntu/Debian server.
2. Point your DNS name to the new server.
3. Clone this repo and run `sudo ./install.sh`.
4. Add at least one admin SSH key before disabling password login.
5. Create `/etc/nginx/.htpasswd_tunnel_registry` with `htpasswd`.
6. Reload nginx and test:
   - `/`
   - `/api/tunnels`
   - `/admin/devices/`
7. Create devices from the admin UI.
8. Copy each generated PEM file to the target device.
