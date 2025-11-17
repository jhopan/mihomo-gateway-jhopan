#!/bin/bash

echo "================================================"
echo "AUTO TEST ALL CHANNELS - Find the best one!"
echo "================================================"
echo ""

CHANNELS=(1 6 11)
BEST_CHANNEL=6
MAX_ATTEMPTS=3

for CHAN in "${CHANNELS[@]}"; do
    echo ""
    echo "========================================"
    echo "Testing Channel $CHAN"
    echo "========================================"
    
    # Stop services
    sudo systemctl stop hostapd 2>/dev/null
    sudo pkill -9 hostapd 2>/dev/null
    sleep 2
    
    # Create config for this channel
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway-Ch${CHAN}
hw_mode=g
channel=${CHAN}
country_code=ID
ieee80211n=1
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_pairwise=TKIP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
dtim_period=2
ap_max_inactivity=0
disassoc_low_ack=0
skip_inactivity_poll=1
ENDCONFIG
    
    # Reset interface
    sudo ip link set wlp2s0 down
    sleep 1
    sudo /usr/sbin/iw dev wlp2s0 set type managed
    sudo ip link set wlp2s0 up
    sleep 2
    sudo ip addr flush dev wlp2s0
    sudo /usr/sbin/iw dev wlp2s0 set type __ap
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    sleep 1
    
    # Start hostapd
    sudo systemctl start hostapd
    sleep 3
    
    # Check if started successfully
    if sudo systemctl is-active --quiet hostapd; then
        echo "✅ Channel $CHAN: hostapd started OK"
        echo ""
        echo "Network: Mihomo-Gateway-Ch${CHAN}"
        echo "Password: mihomo2024"
        echo ""
        echo "Please try to connect from phone now!"
        echo "I'll monitor for 30 seconds..."
        echo ""
        
        # Monitor for 30 seconds
        timeout 30 sudo journalctl -u hostapd -f -n 0 2>/dev/null | grep --line-buffered "authenticated\|associated\|WPA.*completed\|deauthenticated" &
        MONITOR_PID=$!
        
        sleep 30
        
        # Check if any client connected
        CLIENT_COUNT=$(sudo hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:")
        
        kill $MONITOR_PID 2>/dev/null
        
        if [ "$CLIENT_COUNT" -gt 0 ]; then
            echo ""
            echo "🎉 SUCCESS! Channel $CHAN has $CLIENT_COUNT client(s) connected!"
            BEST_CHANNEL=$CHAN
            break
        else
            echo ""
            echo "❌ Channel $CHAN: No successful connection"
        fi
    else
        echo "❌ Channel $CHAN: hostapd failed to start"
    fi
    
    echo ""
    read -p "Press Enter to try next channel (or Ctrl+C to stop)..." -t 5
done

echo ""
echo "================================================"
echo "Best channel found: $BEST_CHANNEL"
echo "================================================"
echo ""

if [ "$CLIENT_COUNT" -gt 0 ]; then
    echo "✅ Client connected on channel $BEST_CHANNEL!"
    echo "This configuration works! Keeping it..."
    echo ""
    echo "To make permanent, run:"
    echo "  sudo systemctl enable hostapd"
    echo "  sudo systemctl enable dnsmasq"
else
    echo "❌ No channel worked with WPA2"
    echo ""
    echo "Last resort: Try OPEN network"
    echo "  bash fix-open-network.sh"
    echo ""
    echo "OR: Check if phone has MAC randomization enabled"
    echo "    Disable it in WiFi advanced settings"
fi
