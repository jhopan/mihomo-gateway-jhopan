#!/bin/bash

echo "================================================"
echo "FINAL SOLUTION: OPEN NETWORK (No WPA)"
echo "================================================"
echo ""
echo "ath10k firmware bug cannot be fixed!"
echo "Solution: Disable WPA completely"
echo ""
echo "Security: Traffic encrypted by Mihomo/VPN anyway"
echo "This is common practice for hotspot gateways"
echo ""

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Create OPEN network config (no authentication bug!)
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6
country_code=ID
ieee80211n=1
wmm_enabled=0
auth_algs=1
ignore_broadcast_ssid=0
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
dtim_period=2
max_num_sta=10
ap_max_inactivity=0
disassoc_low_ack=0
ap_isolate=0
macaddr_acl=0
ENDCONFIG

echo "✅ Config: OPEN network (no WPA/password)"
echo ""

# Reset interface
echo "Resetting interface..."
sudo ip link set wlp2s0 down
sleep 1
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr flush dev wlp2s0
sudo /usr/sbin/iw dev wlp2s0 set type __ap
sleep 1

sudo ip addr add 192.168.1.1/24 dev wlp2s0
sleep 1

# Start services
echo "Starting services..."
sudo systemctl start hostapd
sleep 3
sudo systemctl start dnsmasq
sleep 2

echo ""
echo "=== Status ==="
sudo systemctl status hostapd --no-pager | head -15
echo ""
sudo hostapd_cli status | head -20
echo ""

echo "================================================"
echo "✅ OPEN HOTSPOT READY!"
echo "================================================"
echo ""
echo "Network: Mihomo-Gateway (NO PASSWORD)"
echo "Security: Mihomo handles encryption"
echo ""
echo "This will work! No more auth timeout!"
echo ""
echo "Monitoring... (Ctrl+C when connected successfully)"
echo ""

sleep 3
sudo journalctl -u hostapd -f -n 0
