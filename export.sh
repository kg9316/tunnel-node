#!/usr/bin/env bash
mkdir -p ~/tunnel-export-full/bin
mkdir -p ~/tunnel-export-full/systemd
mkdir -p ~/tunnel-export-full/ssh
mkdir -p ~/tunnel-export-full/nginx
mkdir -p ~/tunnel-export-full/state
mkdir -p ~/tunnel-export-full/meta

cp -f /usr/local/bin/tunnel-admin.py ~/tunnel-export-full/bin/ 2>/dev/null || true
cp -f /usr/local/bin/tunnel-registry.py ~/tunnel-export-full/bin/ 2>/dev/null || true
cp -f /usr/local/bin/tunnel-registry-http.py ~/tunnel-export-full/bin/ 2>/dev/null || true
cp -f /usr/local/bin/tunnel-relay-manager.py ~/tunnel-export-full/bin/ 2>/dev/null || true

cp -f /etc/systemd/system/tunnel-admin.service ~/tunnel-export-full/systemd/ 2>/dev/null || true
cp -f /etc/systemd/system/tunnel-registry.service ~/tunnel-export-full/systemd/ 2>/dev/null || true
cp -f /etc/systemd/system/tunnel-registry.timer ~/tunnel-export-full/systemd/ 2>/dev/null || true
cp -f /etc/systemd/system/tunnel-registry-http.service ~/tunnel-export-full/systemd/ 2>/dev/null || true
cp -f /etc/systemd/system/tunnel-relay-manager.service ~/tunnel-export-full/systemd/ 2>/dev/null || true

cp -f /etc/ssh/sshd_config.d/tunnel.conf ~/tunnel-export-full/ssh/ 2>/dev/null || true
cp -f /etc/ssh/sshd_config ~/tunnel-export-full/ssh/sshd_config.main 2>/dev/null || true

cp -f /etc/nginx/sites-available/tunnel-registry ~/tunnel-export-full/nginx/ 2>/dev/null || true
cp -f /etc/nginx/sites-available/tunnel ~/tunnel-export-full/nginx/ 2>/dev/null || true
cp -f /etc/nginx/nginx.conf ~/tunnel-export-full/nginx/ 2>/dev/null || true

cp -f /var/lib/tunnel-registry/devices.json ~/tunnel-export-full/state/ 2>/dev/null || true
cp -f /var/lib/tunnel-registry/active-tunnels.json ~/tunnel-export-full/state/ 2>/dev/null || true
cp -f /var/lib/tunnel-registry/relay-state.json ~/tunnel-export-full/state/ 2>/dev/null || true

sudo systemctl cat tunnel-admin.service > ~/tunnel-export-full/meta/systemctl-cat-tunnel-admin.txt 2>/dev/null || true
sudo systemctl cat tunnel-registry.service > ~/tunnel-export-full/meta/systemctl-cat-tunnel-registry.txt 2>/dev/null || true
sudo systemctl cat tunnel-registry-http.service > ~/tunnel-export-full/meta/systemctl-cat-tunnel-registry-http.txt 2>/dev/null || true
sudo systemctl cat tunnel-relay-manager.service > ~/tunnel-export-full/meta/systemctl-cat-tunnel-relay-manager.txt 2>/dev/null || true

sudo ufw status verbose > ~/tunnel-export-full/meta/ufw-status.txt 2>/dev/null || true
sudo ss -tlnp > ~/tunnel-export-full/meta/ss-tlnp.txt 2>/dev/null || true
ps -ef > ~/tunnel-export-full/meta/ps-ef.txt 2>/dev/null || true

echo "=== BIN ===" > ~/tunnel-export-full/meta/export-check.txt
ls -l ~/tunnel-export-full/bin >> ~/tunnel-export-full/meta/export-check.txt
echo "" >> ~/tunnel-export-full/meta/export-check.txt
echo "=== SYSTEMD ===" >> ~/tunnel-export-full/meta/export-check.txt
ls -l ~/tunnel-export-full/systemd >> ~/tunnel-export-full/meta/export-check.txt
echo "" >> ~/tunnel-export-full/meta/export-check.txt
echo "=== SSH ===" >> ~/tunnel-export-full/meta/export-check.txt
ls -l ~/tunnel-export-full/ssh >> ~/tunnel-export-full/meta/export-check.txt
echo "" >> ~/tunnel-export-full/meta/export-check.txt
echo "=== NGINX ===" >> ~/tunnel-export-full/meta/export-check.txt
ls -l ~/tunnel-export-full/nginx >> ~/tunnel-export-full/meta/export-check.txt
echo "" >> ~/tunnel-export-full/meta/export-check.txt
echo "=== STATE ===" >> ~/tunnel-export-full/meta/export-check.txt
ls -l ~/tunnel-export-full/state >> ~/tunnel-export-full/meta/export-check.txt

tar -czf ~/tunnel-export-full.tar.gz -C ~ tunnel-export-full

echo "Created: /home/$USER/tunnel-export-full.tar.gz"
echo "Check summary:"
cat ~/tunnel-export-full/meta/export-check.txt
