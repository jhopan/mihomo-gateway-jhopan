#!/bin/bash

echo "=== ULTIMATE FIX: Driver-level timeout workaround ==="
echo ""
echo "Your WiFi chipset has hardcoded authentication timeout"
echo "that cannot be disabled. We need to work around it."
echo ""

# Stop everything
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo pkill -9 hostapd
sleep 3

# Create MINIMAL config - less features = less bugs
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
country_code=ID
auth_algs=1
ignore_broadcast_ssid=0
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ap_max_inactivity=0
disassoc_low_ack=0
ap_isolate=0
beacon_int=100
dtim_period=1
wpa_group_rekey=0
wpa_ptk_rekey=0
wpa_gmk_rekey=0
ENDCONFIG

echo "Config applied - Ultra minimal with channel 1"
echo ""

# COMPLETE interface reset
echo "=== Complete WiFi reset ==="
sudo rfkill unblock wifi
sleep 1

sudo ip link set wlp2s0 down
sudo /usr/sbin/iw dev wlp2s0 set type managed
sudo ip link set wlp2s0 up
sleep 2

# Remove all existing network configs
sudo ip addr flush dev wlp2s0
sudo ip route flush dev wlp2s0

sudo ip link set wlp2s0 down
sleep 2
sudo ip link set wlp2s0 up
sleep 2

# Set to AP mode
sudo /usr/sbin/iw dev wlp2s0 set type __ap
sleep 2

# Configure IP
sudo ip addr add 192.168.1.1/24 dev wlp2s0
sudo ip link set wlp2s0 up
sleep 1

echo "Interface ready"
echo ""

# Start hostapd in FOREGROUND first to see errors
echo "=== Starting hostapd (foreground test) ==="
timeout 10 sudo hostapd -dd /etc/hostapd/hostapd.conf 2>&1 | head -100 &
HOSTAPD_PID=$!
sleep 8

# Kill foreground test
sudo kill $HOSTAPD_PID 2>/dev/null
sudo pkill -9 hostapd
sleep 2

# Start as service
echo ""
echo "=== Starting as service ==="
sudo systemctl start hostapd
sleep 3

sudo systemctl start dnsmasq
sleep 2

echo ""
echo "=== Status ==="
sudo systemctl status hostapd --no-pager | head -15
echo ""

# Check what hostapd actually loaded
echo "=== Actual hostapd config loaded ==="
sudo hostapd_cli status | grep -E "state|channel|num_sta"
echo ""

# Show current WiFi info
echo "=== WiFi interface info ==="
/usr/sbin/iw dev wlp2s0 info
echo ""

echo "=== IMPORTANT: Try connecting from phone NOW ==="
echo "Watch for 'deauthenticated due to inactivity' below"
echo "If you see it, the problem is HARDWARE/DRIVER bug"
echo ""
echo "Press Ctrl+C when done"
echo ""

sudo journalctl -u hostapd -f -n 0
