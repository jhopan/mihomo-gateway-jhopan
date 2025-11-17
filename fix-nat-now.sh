#!/bin/bash

echo "🔧 Fixing NAT routing for current USB interface..."

# Detect current USB interface (enx* or usb* - typically USB tethering)
# Priority: enx* > usb* > any non-standard interface
USB_IFACE=$(ip -o link show | awk -F': ' '$2 ~ /^enx/ {print $2; exit}')

if [ -z "$USB_IFACE" ]; then
    # Try usb* pattern
    USB_IFACE=$(ip -o link show | awk -F': ' '$2 ~ /^usb/ {print $2; exit}')
fi

if [ -z "$USB_IFACE" ]; then
    echo "❌ No USB interface found!"
    echo "Available interfaces:"
    ip link show
    exit 1
fi

echo "✅ USB interface detected: $USB_IFACE"

# Detect WiFi interface
WIFI_IFACE=$(iw dev | grep Interface | awk '{print $2}')

if [ -z "$WIFI_IFACE" ]; then
    echo "❌ No WiFi interface found!"
    exit 1
fi

echo "✅ WiFi interface: $WIFI_IFACE"

# Flush old NAT rules
echo "🧹 Flushing old NAT rules..."
sudo iptables -t nat -F POSTROUTING
sudo iptables -F FORWARD

# Add new NAT rules for current USB interface
echo "➕ Adding new NAT rules..."
sudo iptables -t nat -A POSTROUTING -o $USB_IFACE -j MASQUERADE
sudo iptables -A FORWARD -i $WIFI_IFACE -o $USB_IFACE -j ACCEPT
sudo iptables -A FORWARD -i $USB_IFACE -o $WIFI_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Enable IP forwarding
echo "📡 Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
sudo sysctl -w net.ipv6.conf.all.forwarding=0 > /dev/null

# Restart dnsmasq to update DNS routing
echo "🔄 Restarting dnsmasq..."
sudo systemctl restart dnsmasq

echo ""
echo "✅ NAT routing fixed!"
echo ""
echo "Current routing:"
sudo iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
echo ""
echo "Test internet from hotspot client: ping 8.8.8.8"
