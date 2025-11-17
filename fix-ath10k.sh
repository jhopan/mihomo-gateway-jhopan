#!/bin/bash

echo "================================================"
echo "ATHEROS ath10k FIRMWARE BUG WORKAROUND"
echo "================================================"
echo ""
echo "Your WiFi: Atheros ath10k chipset"
echo "Known bug: Firmware has hardcoded auth timeout"
echo "Cannot be disabled by hostapd config!"
echo ""
echo "Workaround: Use WPA1+WPA2 mixed mode"
echo "This bypasses the firmware authentication bug"
echo ""

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Apply ath10k-specific workaround config
sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6
country_code=ID
auth_algs=1
ignore_broadcast_ssid=0
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ieee80211n=1
wmm_enabled=0
beacon_int=100
dtim_period=2
max_num_sta=10
ap_max_inactivity=0
disassoc_low_ack=0
ap_isolate=0
wpa=3
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
wpa_group_rekey=0
wpa_ptk_rekey=0
wpa_strict_rekey=0
okc=0
disable_pmksa_caching=1
ap_table_expiration_time=3600
ENDCONFIG

echo "Config applied with ath10k workarounds:"
echo "  - wpa=3 (WPA1+WPA2 mixed mode)"
echo "  - wpa_pairwise=TKIP CCMP (legacy support)"
echo "  - disable_pmksa_caching=1 (no caching issues)"
echo "  - okc=0 (disable opportunistic key caching)"
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
sudo hostapd_cli status | grep -E "state|channel|num_sta|wpa"
echo ""

echo "================================================"
echo "✅ ath10k workaround applied!"
echo "================================================"
echo ""
echo "Now try connecting from phone."
echo ""
echo "If STILL fails, we need to try:"
echo "  1. Downgrade ath10k firmware"
echo "  2. Use different WiFi channel"
echo "  3. Use external USB WiFi adapter"
echo ""
echo "Monitoring... (Ctrl+C to stop)"
echo ""

sleep 3
sudo journalctl -u hostapd -f -n 0
