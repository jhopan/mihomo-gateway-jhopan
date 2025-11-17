#!/bin/bash

echo "=== Quick Fix: Hotspot Internet ==="

# Kill all yang pakai WiFi
sudo pkill -9 wpa_supplicant 2>/dev/null || true
sudo pkill -9 NetworkManager 2>/dev/null || true

# Kill all yang pakai port 53
sudo pkill -9 systemd-resolve 2>/dev/null || true
sudo lsof -ti:53 | xargs -r sudo kill -9 2>/dev/null || true

# Detect interfaces
WIFI=$(iw dev | grep Interface | awk '{print $2}')
USB=$(ip -o link show | awk -F': ' '$2 ~ /^enx/ {print $2; exit}')

echo "WiFi: $WIFI"
echo "USB: $USB"

# Configure WiFi interface
sudo ip addr flush dev $WIFI
sudo ip link set $WIFI up
sudo ip addr add 192.168.2.1/24 dev $WIFI

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Setup NAT
sudo iptables -t nat -F POSTROUTING
sudo iptables -F FORWARD
sudo iptables -t nat -A POSTROUTING -o $USB -j MASQUERADE
sudo iptables -A FORWARD -i $WIFI -o $USB -j ACCEPT
sudo iptables -A FORWARD -i $USB -o $WIFI -m state --state RELATED,ESTABLISHED -j ACCEPT

# Simple dnsmasq config (minimal)
sudo tee /etc/dnsmasq.conf > /dev/null << EOF
interface=$WIFI
bind-interfaces
port=53
dhcp-range=192.168.1.10,192.168.1.100,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
server=8.8.8.8
server=1.1.1.1
no-resolv
EOF

# Fix resolv.conf
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# Restart dnsmasq
sudo systemctl stop dnsmasq
sleep 1
sudo systemctl start dnsmasq

# Check dnsmasq
if systemctl is-active --quiet dnsmasq; then
    echo "✅ dnsmasq running"
else
    echo "❌ dnsmasq failed:"
    sudo journalctl -u dnsmasq -n 20 --no-pager
fi

# Restart hostapd
sudo systemctl restart hostapd
sleep 2

echo ""
echo "=== Status ==="
echo "hostapd: $(systemctl is-active hostapd)"
echo "dnsmasq: $(systemctl is-active dnsmasq)"
echo "NAT: $(sudo iptables -t nat -L POSTROUTING -n | grep MASQUERADE | wc -l) rules"
echo ""
echo "Test from phone: ping 8.8.8.8"
