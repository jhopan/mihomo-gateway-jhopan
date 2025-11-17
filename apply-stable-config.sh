#!/bin/bash

echo "=== Fixing authentication timeout issue ==="

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Create config file directly
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
country_code=ID
ieee80211n=1
auth_algs=1
ignore_broadcast_ssid=0
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
wmm_enabled=0
ap_max_inactivity=0
max_listen_interval=65535
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0
beacon_int=100
dtim_period=2
max_num_sta=10
ieee80211d=0
ENDCONFIG

echo "Config applied!"

# Reset interface
echo "Resetting WiFi interface..."
sudo ip link set wlp2s0 down
sudo /usr/sbin/iw dev wlp2s0 set type managed 2>/dev/null
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr flush dev wlp2s0
sudo ip link set wlp2s0 down
sleep 1
sudo ip link set wlp2s0 up
sleep 2

sudo /usr/sbin/iw dev wlp2s0 set type __ap 2>/dev/null
sleep 1

sudo ip addr add 192.168.1.1/24 dev wlp2s0
sleep 1

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
echo "=== Monitoring logs (Ctrl+C to stop) ==="
echo "Coba konek dari HP sekarang..."
sleep 3
sudo journalctl -u hostapd -f -n 30
