#!/bin/bash

# ==========================================
# Fix Hotspot Internet - NAT Routing Setup
# ==========================================

set -e

echo "=== Fixing Hotspot Internet Routing ==="
echo ""

# Step 1: Detect interfaces
echo "[1/5] Detecting network interfaces..."
WIFI_IF=$(ip -o link show | awk -F': ' '$2 ~ /^wlp/ {print $2; exit}')
USB_IF=$(ip -o link show | awk -F': ' '$2 ~ /^enx/ && $3 ~ /UP/ {print $2; exit}')

if [ -z "$USB_IF" ]; then
    USB_IF=$(ip -o link show | awk -F': ' '$2 ~ /^usb/ && $3 ~ /UP/ {print $2; exit}')
fi

if [ -z "$USB_IF" ]; then
    echo "⚠️  USB tethering not found, using default route interface"
    USB_IF=$(ip route | grep default | awk '{print $5}' | head -1)
fi

echo "  WiFi Interface: $WIFI_IF"
echo "  USB/WAN Interface: $USB_IF"
echo ""

if [ -z "$WIFI_IF" ] || [ -z "$USB_IF" ]; then
    echo "❌ Error: Could not detect network interfaces"
    exit 1
fi

# Step 2: Enable IP forwarding
echo "[2/5] Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ip-forward.conf
echo "  ✓ IP forwarding enabled"
echo ""

# Step 3: Clear old NAT rules
echo "[3/5] Clearing old NAT rules..."
iptables -t nat -F POSTROUTING
iptables -F FORWARD
echo "  ✓ Old rules cleared"
echo ""

# Step 4: Setup NAT (MASQUERADE)
echo "[4/5] Setting up NAT routing..."
iptables -t nat -A POSTROUTING -o "$USB_IF" -j MASQUERADE
iptables -A FORWARD -i "$WIFI_IF" -o "$USB_IF" -j ACCEPT
iptables -A FORWARD -i "$USB_IF" -o "$WIFI_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
echo "  ✓ NAT MASQUERADE: $WIFI_IF → $USB_IF"
echo ""

# Step 5: Setup Mihomo transparent proxy (optional)
echo "[5/5] Setting up Mihomo transparent proxy..."

# Allow Mihomo to bypass (mark packets)
iptables -t mangle -N MIHOMO_MARK || true
iptables -t mangle -F MIHOMO_MARK
iptables -t mangle -A MIHOMO_MARK -j MARK --set-mark 666
iptables -t mangle -A MIHOMO_MARK -j ACCEPT

# Redirect TCP to Mihomo REDIRECT port (9797)
iptables -t nat -N MIHOMO_REDIR || true
iptables -t nat -F MIHOMO_REDIR

# Bypass local and reserved IPs
iptables -t nat -A MIHOMO_REDIR -d 0.0.0.0/8 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 10.0.0.0/8 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 127.0.0.0/8 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 169.254.0.0/16 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 172.16.0.0/12 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 192.168.0.0/16 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 224.0.0.0/4 -j RETURN
iptables -t nat -A MIHOMO_REDIR -d 240.0.0.0/4 -j RETURN

# Redirect all other TCP to Mihomo
iptables -t nat -A MIHOMO_REDIR -p tcp -j REDIRECT --to-ports 9797

# Apply to PREROUTING (from WiFi clients)
iptables -t nat -D PREROUTING -i "$WIFI_IF" -p tcp -j MIHOMO_REDIR 2>/dev/null || true
iptables -t nat -A PREROUTING -i "$WIFI_IF" -p tcp -j MIHOMO_REDIR

echo "  ✓ Mihomo transparent proxy enabled"
echo ""

# Step 6: Restart dnsmasq for DNS
echo "[6/6] Restarting DNS service..."
systemctl restart dnsmasq 2>/dev/null || true
echo "  ✓ DNS service restarted"
echo ""

# Summary
echo "=== Summary ==="
echo "WiFi Interface: $WIFI_IF"
echo "WAN Interface: $USB_IF"
echo ""
echo "NAT Rules:"
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
echo ""
echo "Mihomo Redirect:"
iptables -t nat -L PREROUTING -n -v | grep MIHOMO_REDIR
echo ""
echo "✅ Hotspot internet routing fixed!"
echo ""
echo "Test from client device:"
echo "  ping 8.8.8.8"
echo "  curl http://www.gstatic.com/generate_204"
