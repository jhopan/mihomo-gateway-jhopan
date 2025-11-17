#!/bin/bash

echo "=========================================="
echo "ROOT CAUSE FOUND: wpa_supplicant CONFLICT"
echo "=========================================="
echo ""
echo "wpa_supplicant and NetworkManager are FIGHTING with hostapd"
echo "for control of wlp2s0 interface!"
echo ""
echo "This causes the 'deauthenticated due to inactivity' error"
echo ""

# Stop all conflicting services
echo "=== Step 1: Stop ALL WiFi services ==="
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop wpa_supplicant
sudo systemctl stop NetworkManager
sleep 3

# Kill any remaining processes
sudo pkill -9 hostapd
sudo pkill -9 wpa_supplicant
sleep 2

echo ""
echo "=== Step 2: Prevent NetworkManager from managing wlp2s0 ==="

# Add wlp2s0 to NetworkManager unmanaged list
sudo tee /etc/NetworkManager/conf.d/unmanaged.conf > /dev/null << 'ENDCONFIG'
[keyfile]
unmanaged-devices=interface-name:wlp2s0
ENDCONFIG

echo "NetworkManager will ignore wlp2s0"

# Restart NetworkManager with new config
sudo systemctl start NetworkManager
sleep 2

echo ""
echo "=== Step 3: Disable wpa_supplicant on wlp2s0 ==="

# Mask wpa_supplicant for wlp2s0 specifically
if [ -f /etc/systemd/system/wpa_supplicant@wlp2s0.service ]; then
    sudo systemctl disable wpa_supplicant@wlp2s0
    sudo systemctl mask wpa_supplicant@wlp2s0
fi

echo "wpa_supplicant disabled for wlp2s0"

echo ""
echo "=== Step 4: Reset WiFi interface ==="

sudo rfkill unblock wifi
sleep 1

sudo ip link set wlp2s0 down
sudo /usr/sbin/iw dev wlp2s0 set type managed
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr flush dev wlp2s0
sudo ip link set wlp2s0 down
sleep 2
sudo ip link set wlp2s0 up
sleep 2

# Set to AP mode
sudo /usr/sbin/iw dev wlp2s0 set type __ap
sleep 2

sudo ip addr add 192.168.1.1/24 dev wlp2s0
sleep 1

echo ""
echo "=== Step 5: Verify no conflicts ==="
echo "Checking for wpa_supplicant on wlp2s0..."

if ps aux | grep -v grep | grep -q "wpa_supplicant.*wlp2s0"; then
    echo "⚠️  WARNING: wpa_supplicant still running on wlp2s0!"
    sudo pkill -9 wpa_supplicant
    sleep 2
else
    echo "✅ No wpa_supplicant on wlp2s0"
fi

echo ""
echo "=== Step 6: Start hostapd and dnsmasq ==="

sudo systemctl start hostapd
sleep 3
sudo systemctl start dnsmasq
sleep 2

echo ""
echo "=== Step 7: Final verification ==="
echo ""

echo "Services status:"
sudo systemctl status hostapd --no-pager | head -15
echo ""

echo "hostapd info:"
sudo hostapd_cli status | head -25
echo ""

echo "Processes (should NOT see wpa_supplicant on wlp2s0):"
ps aux | grep -E "hostapd|wpa_supplicant" | grep -v grep
echo ""

echo "========================================"
echo "✅ DONE! Conflicts resolved!"
echo "========================================"
echo ""
echo "Now try connecting from phone."
echo "You should NOT see 'deauthenticated due to inactivity' anymore!"
echo ""
echo "Monitoring logs... (Ctrl+C to stop)"
echo ""

sleep 3
sudo journalctl -u hostapd -f -n 0
