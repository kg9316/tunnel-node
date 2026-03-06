#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ADMIN_USER_DEFAULT="kg9316"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo ./install.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/9] Installing packages"
apt-get update
apt-get install -y openssh-server nginx python3 python3-pip socat ufw fail2ban apache2-utils

echo "[2/9] Ensuring tunnel user exists"
id tunnel >/dev/null 2>&1 || useradd -m -s /bin/bash tunnel
mkdir -p /home/tunnel/.ssh
chmod 700 /home/tunnel/.ssh
touch /home/tunnel/.ssh/authorized_keys
chmod 600 /home/tunnel/.ssh/authorized_keys
chown -R tunnel:tunnel /home/tunnel/.ssh

echo "[3/9] Installing application files"
install -m 0755 "$REPO_DIR/bin/tunnel-admin.py" /usr/local/bin/tunnel-admin.py
install -m 0755 "$REPO_DIR/bin/tunnel-registry.py" /usr/local/bin/tunnel-registry.py
install -m 0755 "$REPO_DIR/bin/tunnel-registry-http.py" /usr/local/bin/tunnel-registry-http.py
sed -i 's/$//' /usr/local/bin/tunnel-admin.py /usr/local/bin/tunnel-registry.py /usr/local/bin/tunnel-registry-http.py

echo "[4/9] Installing systemd units"
install -m 0644 "$REPO_DIR/systemd/tunnel-admin.service" /etc/systemd/system/tunnel-admin.service
install -m 0644 "$REPO_DIR/systemd/tunnel-registry.service" /etc/systemd/system/tunnel-registry.service
install -m 0644 "$REPO_DIR/systemd/tunnel-registry.timer" /etc/systemd/system/tunnel-registry.timer
install -m 0644 "$REPO_DIR/systemd/tunnel-registry-http.service" /etc/systemd/system/tunnel-registry-http.service

echo "[5/9] Preparing state"
mkdir -p /var/lib/tunnel-registry
[[ -f /var/lib/tunnel-registry/devices.json ]] || cp "$REPO_DIR/state/devices.json.example" /var/lib/tunnel-registry/devices.json
[[ -f /var/lib/tunnel-registry/active-tunnels.json ]] || cp "$REPO_DIR/state/active-tunnels.json.example" /var/lib/tunnel-registry/active-tunnels.json
[[ -f /var/lib/tunnel-registry/relay-state.json ]] || cp "$REPO_DIR/state/relay-state.json.example" /var/lib/tunnel-registry/relay-state.json
chmod 644 /var/lib/tunnel-registry/*.json

echo "[6/9] Installing SSH config"
install -m 0644 "$REPO_DIR/ssh/tunnel.conf" /etc/ssh/sshd_config.d/tunnel.conf
sshd -t
systemctl restart ssh

echo "[7/9] Installing nginx config"
install -m 0644 "$REPO_DIR/nginx/tunnel-registry.conf" /etc/nginx/sites-available/tunnel-registry
ln -sfn /etc/nginx/sites-available/tunnel-registry /etc/nginx/sites-enabled/tunnel-registry
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl restart nginx

echo "[8/9] Enabling services"
systemctl daemon-reload
systemctl enable --now tunnel-admin.service
systemctl enable --now tunnel-registry.timer
systemctl enable --now tunnel-registry-http.service

echo "[9/9] Firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 40001:50001/tcp
ufw --force enable

cat <<'EOF'

Install complete.

Next steps:
1. Create /etc/nginx/.htpasswd_tunnel_registry with htpasswd.
2. Reload nginx.
3. Add your admin SSH key before disabling password login.
4. Review docs/SSH-HARDENING.md before changing admin auth.

EOF
