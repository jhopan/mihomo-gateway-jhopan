#!/bin/bash

# Script untuk ganti network dari 192.168.1.x ke 192.168.2.x
# Gateway: 192.168.2.1
# DHCP Range: 192.168.2.10 - 192.168.2.100

set -e

echo "========================================"
echo "  Change Network to 192.168.2.x"
echo "========================================"
echo ""
echo "This will change:"
echo "  - Gateway: 192.168.1.1 → 192.168.2.1"
echo "  - DHCP Range: 192.168.1.10-100 → 192.168.2.10-100"
echo "  - Hotspot config, dnsmasq, NAT rules"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Backup configs
echo "[1/8] Backing up configurations..."
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null || true
sudo cp /opt/mihomo-gateway/scripts/hotspot.sh /opt/mihomo-gateway/scripts/hotspot.sh.backup 2>/dev/null || true
sudo cp /opt/mihomo-gateway/scripts/usb-watchdog.sh /opt/mihomo-gateway/scripts/usb-watchdog.sh.backup 2>/dev/null || true
sudo cp /opt/mihomo-gateway/fix-nat-now.sh /opt/mihomo-gateway/fix-nat-now.sh.backup 2>/dev/null || true
echo "  Configs backed up"

# Stop services
echo "[2/8] Stopping services..."
sudo systemctl stop hostapd dnsmasq

# Update all scripts with 192.168.1 references
echo "[3/8] Updating all config files..."
# Update hotspot.sh
if [ -f /opt/mihomo-gateway/scripts/hotspot.sh ]; then
    sudo sed -i 's/192\.168\.1\./192.168.2./g' /opt/mihomo-gateway/scripts/hotspot.sh
    echo "  - hotspot.sh updated"
fi

# Update usb-watchdog.sh
if [ -f /opt/mihomo-gateway/scripts/usb-watchdog.sh ]; then
    sudo sed -i 's/192\.168\.1\./192.168.2./g' /opt/mihomo-gateway/scripts/usb-watchdog.sh
    echo "  - usb-watchdog.sh updated"
fi

# Update fix-nat-now.sh
if [ -f /opt/mihomo-gateway/fix-nat-now.sh ]; then
    sudo sed -i 's/192\.168\.1\./192.168.2./g' /opt/mihomo-gateway/fix-nat-now.sh
    echo "  - fix-nat-now.sh updated"
fi

# Update emergency-fix-network.sh
if [ -f /opt/mihomo-gateway/emergency-fix-network.sh ]; then
    sudo sed -i 's/192\.168\.1\./192.168.2./g' /opt/mihomo-gateway/emergency-fix-network.sh
    echo "  - emergency-fix-network.sh updated"
fi

# Update quick-fix-hotspot.sh
if [ -f /opt/mihomo-gateway/quick-fix-hotspot.sh ]; then
    sudo sed -i 's/192\.168\.1\./192.168.2./g' /opt/mihomo-gateway/quick-fix-hotspot.sh
    echo "  - quick-fix-hotspot.sh updated"
fi

# Update dnsmasq.conf
echo "[4/8] Updating dnsmasq config..."
sudo tee /etc/dnsmasq.conf > /dev/null << 'EOF'
interface=wlp2s0
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.2.10,192.168.2.100,12h
dhcp-option=3,192.168.2.1
dhcp-option=6,8.8.8.8
EOF

# Commit changes to git
echo "[5/8] Committing changes to repository..."
cd /opt/mihomo-gateway
git add scripts/hotspot.sh scripts/usb-watchdog.sh fix-nat-now.sh emergency-fix-network.sh quick-fix-hotspot.sh 2>/dev/null || true
git commit -m "Update network configuration: 192.168.1.x → 192.168.2.x" 2>/dev/null || echo "  - No changes to commit"

# Configure WiFi interface with new IP
echo "[6/8] Configuring WiFi interface..."
WIFI_IF="wlp2s0"
sudo ip addr flush dev $WIFI_IF
sudo ip addr add 192.168.2.1/24 dev $WIFI_IF
sudo ip link set $WIFI_IF up

# Update NAT rules
echo "[7/8] Updating NAT rules..."
USB_IF=$(ip link show | grep -oE 'enx[a-f0-9]+' | head -1)
if [ -n "$USB_IF" ]; then
    sudo iptables -t nat -F POSTROUTING
    sudo iptables -F FORWARD
    sudo iptables -t nat -A POSTROUTING -o $USB_IF -j MASQUERADE
    sudo iptables -A FORWARD -i $WIFI_IF -o $USB_IF -j ACCEPT
    sudo iptables -A FORWARD -i $USB_IF -o $WIFI_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
    echo "  NAT rules updated for USB: $USB_IF"
else
    echo "  WARNING: USB interface not found, NAT not updated"
fi

# Start services
echo "[8/8] Starting services..."
sudo systemctl start dnsmasq
sudo systemctl start hostapd

echo ""
echo "========================================"
echo "  Network Changed Successfully!"
echo "========================================"
echo ""
echo "New configuration:"
echo "  Gateway IP: 192.168.2.1"
echo "  DHCP Range: 192.168.2.10 - 192.168.2.100"
echo "  WiFi SSID: Mihomo-Gateway"
echo ""
echo "IMPORTANT:"
echo "  1. Reconnect your phone to hotspot"
echo "  2. WebUI now at: http://192.168.2.1:8080"
echo "  3. CasaOS now at: http://192.168.2.1"
echo "  4. SSH new address: ssh jhopan@192.168.2.1"
echo ""
echo "To revert, restore backups:"
echo "  sudo cp /opt/mihomo-gateway/config/hotspot.conf.backup /opt/mihomo-gateway/config/hotspot.conf"
echo "  sudo cp /etc/dnsmasq.conf.backup /etc/dnsmasq.conf"
echo "  sudo cp /opt/mihomo-gateway/scripts/hotspot.sh.backup /opt/mihomo-gateway/scripts/hotspot.sh"
echo ""
