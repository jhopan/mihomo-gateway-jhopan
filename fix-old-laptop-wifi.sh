#!/bin/bash

echo "================================================"
echo "INTEL/OLD LAPTOP WIFI OPTIMIZATION"
echo "================================================"
echo ""
echo "Optimizing for old WiFi chipsets with stability issues"
echo ""

# Check WiFi driver
echo "=== Step 1: Identify WiFi driver ==="
DRIVER=$(basename $(readlink /sys/class/net/wlp2s0/device/driver) 2>/dev/null || echo "unknown")
echo "WiFi Driver: $DRIVER"
echo ""

if [[ "$DRIVER" == "iwlwifi" ]]; then
    echo "✅ Intel WiFi detected - applying Intel-specific fixes"
    INTEL_WIFI=true
else
    echo "⚠️  Driver: $DRIVER - applying generic old laptop fixes"
    INTEL_WIFI=false
fi
echo ""

# Disable power saving
echo "=== Step 2: Disable WiFi power saving ==="
sudo /usr/sbin/iw dev wlp2s0 set power_save off
echo "✅ Power saving disabled for current session"
echo ""

# Make power saving disable permanent
echo "=== Step 3: Make power saving disable permanent ==="
sudo mkdir -p /etc/NetworkManager/conf.d/
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'ENDCONFIG'
[connection]
wifi.powersave = 2
ENDCONFIG
echo "✅ Power saving will stay disabled after reboot"
echo ""

# Update Intel microcode if Intel WiFi
if [ "$INTEL_WIFI" = true ]; then
    echo "=== Step 4: Update Intel microcode ==="
    sudo apt update -qq
    sudo apt install -y intel-microcode
    echo "✅ Intel microcode updated"
    echo ""
fi

# Stop services
echo "=== Step 5: Apply optimized hostapd config ==="
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Create optimized config for old laptops
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
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_pairwise=TKIP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
dtim_period=2
max_num_sta=10
ap_max_inactivity=600
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0
macaddr_acl=0
wpa_group_rekey=86400
wpa_ptk_rekey=600
eapol_key_index_workaround=1
ENDCONFIG

echo "✅ Config optimized for old WiFi chipsets:"
echo "   - Channel 6 (most stable for old chips)"
echo "   - hw_mode=g (2.4GHz only, no fancy stuff)"
echo "   - ap_max_inactivity=600 (10 min timeout)"
echo "   - disassoc_low_ack=0 (don't kick on weak signal)"
echo "   - Long rekey intervals (less interruption)"
echo ""

# Reset interface completely
echo "=== Step 6: Complete interface reset ==="
sudo pkill -9 hostapd
sudo pkill -9 wpa_supplicant
sleep 2

sudo rfkill unblock wifi
sleep 1

sudo ip link set wlp2s0 down
sudo /usr/sbin/iw reg set ID
sleep 1
sudo /usr/sbin/iw dev wlp2s0 set power_save off
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

sudo /usr/sbin/iw dev wlp2s0 set power_save off
sudo ip addr add 192.168.1.1/24 dev wlp2s0
sudo ip link set wlp2s0 up
sleep 1

echo "✅ Interface reset complete"
echo ""

# Start services
echo "=== Step 7: Start services ==="
sudo systemctl start hostapd
sleep 5
sudo systemctl start dnsmasq
sleep 3

# Restart NetworkManager with new power save config
sudo systemctl restart NetworkManager
sleep 2

echo ""
echo "=== Step 8: Verification ==="
echo ""

# Check services
if sudo systemctl is-active --quiet hostapd; then
    echo "✅ hostapd: RUNNING"
else
    echo "❌ hostapd: FAILED"
fi

if sudo systemctl is-active --quiet dnsmasq; then
    echo "✅ dnsmasq: RUNNING"
else
    echo "❌ dnsmasq: FAILED"
fi

echo ""
sudo hostapd_cli status | head -25
echo ""

# Check power saving status
echo "Power saving status:"
/usr/sbin/iw dev wlp2s0 get power_save
echo ""

# Check for Intel WiFi errors
if [ "$INTEL_WIFI" = true ]; then
    echo "=== Intel WiFi driver logs (checking for errors) ==="
    dmesg | grep -i "iwlwifi\|iwl" | tail -20
    echo ""
fi

echo "================================================"
echo "✅ OLD LAPTOP OPTIMIZATION COMPLETE!"
echo "================================================"
echo ""
echo "Try connecting now. Should be much more stable!"
echo ""
echo "If still having issues, please send:"
echo "  1. Full output of: dmesg | grep -i iwlwifi"
echo "  2. WiFi card model: lspci | grep -i wireless"
echo ""
echo "Monitoring... (Ctrl+C to stop)"
echo ""

sleep 3
sudo journalctl -u hostapd -f -n 0
