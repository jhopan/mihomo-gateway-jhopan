#!/bin/bash

cat << 'EOF'
================================================
ULTIMATE SOLUTION: Open Network + Captive Portal
================================================

Since ath10k firmware bug cannot be fixed, we use:
✅ Open network (no WPA auth = no bug)
✅ Captive portal for security/voucher system
✅ Works perfectly for hotspot gateway!

This is how hotels/cafes do it:
- No WiFi password needed
- Login page for authentication
- Perfect for voucher system!

EOF

echo "Applying OPEN network config..."
echo ""

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Create OPEN network config
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6
country_code=ID
ieee80211n=1
wmm_enabled=1
auth_algs=1
ignore_broadcast_ssid=0
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
dtim_period=2
max_num_sta=50
ap_max_inactivity=0
disassoc_low_ack=0
ap_isolate=0
macaddr_acl=0
ENDCONFIG

echo "✅ Config: OPEN network (no password)"
echo ""

# Reset interface properly
echo "Resetting interface..."
sudo pkill -9 hostapd
sudo pkill -9 wpa_supplicant
sleep 2

sudo rfkill unblock wifi
sleep 1

sudo ip link set wlp2s0 down
sudo /usr/sbin/iw dev wlp2s0 set type managed
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr flush dev wlp2s0
sudo ip route flush dev wlp2s0
sudo ip link set wlp2s0 down
sleep 2

sudo /usr/sbin/iw dev wlp2s0 set type __ap
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr add 192.168.1.1/24 dev wlp2s0
sudo ip link set wlp2s0 up
sleep 1

echo ""
echo "Starting services..."
sudo systemctl start hostapd
sleep 5

sudo systemctl start dnsmasq
sleep 3

echo ""
echo "=== Verification ==="
echo ""

# Check services
if sudo systemctl is-active --quiet hostapd; then
    echo "✅ hostapd: RUNNING"
else
    echo "❌ hostapd: FAILED"
    sudo journalctl -u hostapd -n 20 --no-pager
    exit 1
fi

if sudo systemctl is-active --quiet dnsmasq; then
    echo "✅ dnsmasq: RUNNING"
else
    echo "❌ dnsmasq: FAILED"
    sudo journalctl -u dnsmasq -n 20 --no-pager
    exit 1
fi

echo ""
sudo hostapd_cli status | grep -E "state|channel|num_sta"
echo ""

echo "================================================"
echo "✅ OPEN HOTSPOT READY!"
echo "================================================"
echo ""
echo "Network: Mihomo-Gateway (NO PASSWORD)"
echo "Channel: 6 (2.4GHz)"
echo "Max Clients: 50"
echo ""
echo "Connect from phone now - should work instantly!"
echo ""
echo "Next steps for voucher system:"
echo "  1. Install coova-chilli (captive portal)"
echo "  2. Setup FreeRADIUS"
echo "  3. Add voucher management system"
echo ""
echo "Monitoring connections... (Ctrl+C to stop)"
echo ""

sleep 3

# Monitor with better filtering
sudo journalctl -u hostapd -f -n 0 | grep --line-buffered -E "authenticated|associated|AP-STA-CONNECTED|AP-STA-DISCONNECTED|deauthenticated" | while read line; do
    if echo "$line" | grep -q "authenticated"; then
        echo "🔵 $line"
    elif echo "$line" | grep -q "associated"; then
        echo "🟢 $line"
    elif echo "$line" | grep -q "AP-STA-CONNECTED"; then
        echo "✅ $line"
    elif echo "$line" | grep -q "DISCONNECTED"; then
        echo "🔴 $line"
    elif echo "$line" | grep -q "deauth"; then
        echo "⚠️  $line"
    fi
done
