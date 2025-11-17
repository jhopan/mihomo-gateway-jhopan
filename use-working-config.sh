#!/bin/bash

echo "================================================"
echo "REPRODUCE CONFIG THAT WORKED FOR 5 MINUTES"
echo "================================================"
echo ""
echo "You said it worked for 5 minutes before!"
echo "Let's use that EXACT config + improvements"
echo ""

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Use the config from when it worked (with improvements)
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=11
country_code=ID
ieee80211n=1
ieee80211d=1
wmm_enabled=1
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
dtim_period=2
max_num_sta=10
ap_max_inactivity=0
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0
ENDCONFIG

echo "Config: Same as when it worked (channel 11, standard WPA2)"
echo "  + ap_max_inactivity=0 (never timeout after connected)"
echo "  + disassoc_low_ack=0 (don't kick on weak signal)"
echo "  + skip_inactivity_poll=1 (don't check idle)"
echo ""

# Complete reset sequence
echo "Complete interface reset..."
sudo pkill -9 hostapd
sudo pkill -9 wpa_supplicant
sleep 2

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
echo "=== Status ==="
sudo systemctl status hostapd --no-pager | head -20
echo ""
sudo hostapd_cli status | head -25
echo ""

echo "================================================"
echo "✅ Using config that worked before!"
echo "================================================"
echo ""
echo "Try connecting now."
echo "If connected, should stay connected forever (no 5 min timeout)"
echo ""
echo "Monitoring... (Ctrl+C when successfully connected)"
echo ""

sleep 3
sudo journalctl -u hostapd -f -n 0
