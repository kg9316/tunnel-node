#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo ./update.sh"
  exit 1
fi

install -m 0755 "$REPO_DIR/bin/tunnel-admin.py" /usr/local/bin/tunnel-admin.py
install -m 0755 "$REPO_DIR/bin/tunnel-registry.py" /usr/local/bin/tunnel-registry.py
install -m 0755 "$REPO_DIR/bin/tunnel-registry-http.py" /usr/local/bin/tunnel-registry-http.py
sed -i 's/$//' /usr/local/bin/tunnel-admin.py /usr/local/bin/tunnel-registry.py /usr/local/bin/tunnel-registry-http.py

install -m 0644 "$REPO_DIR/systemd/tunnel-admin.service" /etc/systemd/system/tunnel-admin.service
install -m 0644 "$REPO_DIR/systemd/tunnel-registry.service" /etc/systemd/system/tunnel-registry.service
install -m 0644 "$REPO_DIR/systemd/tunnel-registry.timer" /etc/systemd/system/tunnel-registry.timer
install -m 0644 "$REPO_DIR/systemd/tunnel-registry-http.service" /etc/systemd/system/tunnel-registry-http.service
install -m 0644 "$REPO_DIR/ssh/tunnel.conf" /etc/ssh/sshd_config.d/tunnel.conf
install -m 0644 "$REPO_DIR/nginx/tunnel-registry.conf" /etc/nginx/sites-available/tunnel-registry
ln -sfn /etc/nginx/sites-available/tunnel-registry /etc/nginx/sites-enabled/tunnel-registry

sshd -t
nginx -t
systemctl daemon-reload
systemctl restart ssh
systemctl restart nginx
systemctl restart tunnel-admin.service
systemctl restart tunnel-registry-http.service
systemctl restart tunnel-registry.timer

echo "Update complete."
