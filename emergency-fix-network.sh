#!/bin/bash

echo "=== Emergency Network Fix - USB Tethering Restart ==="

# Step 1: Kill all network conflicts
echo "[1/6] Cleaning up network conflicts..."
sudo pkill -9 NetworkManager 2>/dev/null || true
sudo pkill -9 wpa_supplicant 2>/dev/null || true
sudo systemctl stop NetworkManager 2>/dev/null || true

# Step 2: Find problematic USB interface
echo "[2/6] Detecting USB interface..."
USB_IF=$(ip link show | grep -oE 'enx[a-f0-9]+' | head -1)
if [ -z "$USB_IF" ]; then
    echo "❌ No USB interface found!"
    exit 1
fi
echo "Found USB: $USB_IF"

# Step 3: Reset USB interface (fix transmit queue timeout)
echo "[3/6] Resetting USB interface..."
sudo ip link set $USB_IF down
sleep 2
sudo ip link set $USB_IF up
sleep 3

# Wait for interface to get IP
echo "Waiting for DHCP..."
sleep 5

# Step 4: Check if USB has IP
USB_IP=$(ip -4 addr show $USB_IF | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$USB_IP" ]; then
    echo "⚠️  USB interface has no IP, requesting DHCP..."
    sudo dhclient -r $USB_IF 2>/dev/null || true
    sudo dhclient $USB_IF
    sleep 3
fi

# Step 5: Setup routing
echo "[4/6] Setting up routing..."
WIFI_IF=$(iw dev | grep Interface | awk '{print $2}')
echo "WiFi: $WIFI_IF"
echo "USB: $USB_IF"

# Flush and recreate NAT
sudo iptables -t nat -F POSTROUTING
sudo iptables -F FORWARD
sudo iptables -t nat -A POSTROUTING -o $USB_IF -j MASQUERADE
sudo iptables -A FORWARD -i $WIFI_IF -o $USB_IF -j ACCEPT
sudo iptables -A FORWARD -i $USB_IF -o $WIFI_IF -m state --state RELATED,ESTABLISHED -j ACCEPT

# Enable forwarding
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Step 6: Restart services
echo "[5/6] Restarting services..."
sudo systemctl restart dnsmasq
sudo systemctl restart hostapd

echo "[6/6] Testing connectivity..."
if ping -c 2 -W 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet working!"
else
    echo "❌ Internet still down"
    echo ""
    echo "Try unplugging and replugging USB tethering!"
fi

echo ""
echo "=== Status ==="
echo "USB Interface: $USB_IF"
echo "USB IP: $(ip -4 addr show $USB_IF | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo 'No IP')"
echo "WiFi Interface: $WIFI_IF"
echo "NAT Rules: $(sudo iptables -t nat -L POSTROUTING -n | grep -c MASQUERADE)"
echo ""
echo "If still not working:"
echo "1. Unplug USB tethering from phone"
echo "2. Wait 5 seconds"
echo "3. Plug USB tethering back in"
echo "4. Run this script again"
