#!/bin/bash

echo "================================================"
echo "ALTERNATIVE: Simple WEP-style (for ath10k)"
echo "================================================"
echo ""
echo "Uses simpler encryption that ath10k handles better"
echo ""

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Try with absolute minimal WPA config
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=1
country_code=ID
ieee80211n=0
wmm_enabled=0
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ignore_broadcast_ssid=0
ctrl_interface=/var/run/hostapd
beacon_int=100
dtim_period=2
ap_max_inactivity=0
ENDCONFIG

echo "Config: Minimal WPA2, channel 1, no 802.11n"
echo ""

# Complete interface reset
echo "Complete reset..."
sudo rfkill block wifi
sleep 2
sudo rfkill unblock wifi
sleep 2

sudo ip link set wlp2s0 down
sudo /usr/sbin/iw reg set ID
sleep 1
sudo /usr/sbin/iw dev wlp2s0 set type managed
sudo ip link set wlp2s0 up
sleep 3

sudo ip addr flush dev wlp2s0
sudo ip link set wlp2s0 down
sleep 2
sudo /usr/sbin/iw dev wlp2s0 set type __ap
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr add 192.168.1.1/24 dev wlp2s0
sleep 1

# Start services
echo "Starting services..."
sudo systemctl start hostapd
sleep 5
sudo systemctl start dnsmasq
sleep 2

echo ""
echo "=== Status ==="
sudo systemctl status hostapd --no-pager | head -15
echo ""

echo "================================================"
echo "Testing with minimal config + channel 1"
echo "================================================"
echo ""
echo "If this works: ath10k happy with channel 1"
echo "If still fails: Use open network solution"
echo ""

sleep 3
sudo journalctl -u hostapd -f -n 0
