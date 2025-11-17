#!/bin/bash

echo "=== Setting up sudo permissions for WebUI ==="

# Add sudo permissions for www-data user
sudo tee /etc/sudoers.d/mihomo-webui > /dev/null << 'EOF'
# Allow www-data to run commands without password for WebUI
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active hostapd
www-data ALL=(ALL) NOPASSWD: /usr/sbin/hostapd_cli *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/ip *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/iw *
www-data ALL=(ALL) NOPASSWD: /usr/bin/journalctl *
www-data ALL=(ALL) NOPASSWD: /usr/bin/ps *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/iptables *
www-data ALL=(ALL) NOPASSWD: /usr/bin/pgrep *
www-data ALL=(ALL) NOPASSWD: /opt/mihomo-gateway/scripts/hotspot.sh
www-data ALL=(ALL) NOPASSWD: /opt/mihomo-gateway/fix-nat-now.sh
www-data ALL=(ALL) NOPASSWD: /opt/mihomo-gateway/quick-fix-hotspot.sh
www-data ALL=(ALL) NOPASSWD: /usr/bin/bash /opt/mihomo-gateway/scripts/hotspot.sh *
www-data ALL=(ALL) NOPASSWD: /usr/bin/bash /opt/mihomo-gateway/fix-nat-now.sh
www-data ALL=(ALL) NOPASSWD: /usr/bin/bash /opt/mihomo-gateway/quick-fix-hotspot.sh
EOF

# Set correct permissions
sudo chmod 0440 /etc/sudoers.d/mihomo-webui

# Validate sudoers file
if sudo visudo -c; then
    echo "✅ Sudoers configuration valid"
else
    echo "❌ Sudoers configuration invalid!"
    sudo rm /etc/sudoers.d/mihomo-webui
    exit 1
fi

echo ""
echo "✅ Sudo permissions configured for www-data"
echo ""
echo "Test from WebUI user:"
echo "  sudo -u www-data sudo systemctl status mihomo"
