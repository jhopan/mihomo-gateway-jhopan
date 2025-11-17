#!/bin/bash

echo "================================================"
echo "Channel Speed Test - Find FASTEST Channel!"
echo "================================================"
echo ""

# Channels to test (non-overlapping)
CHANNELS=(1 6 11)
RESULTS_FILE="/tmp/channel_speed_test.txt"
> "$RESULTS_FILE"

# Check if speedtest installed (official from Ookla)
if ! command -v speedtest &> /dev/null; then
    echo "Installing speedtest (Ookla official)..."
    echo "Speedtest already installed but may conflict. Using it anyway..."
fi

# Function to get current speed
get_speed() {
    echo "  Running speedtest (30s)..."
    
    # Try official speedtest first
    if command -v speedtest &> /dev/null; then
        SPEED_RESULT=$(speedtest --accept-license --accept-gdpr 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            DOWNLOAD=$(echo "$SPEED_RESULT" | grep "Download:" | awk '{print $2}')
            UPLOAD=$(echo "$SPEED_RESULT" | grep "Upload:" | awk '{print $2}')
            PING=$(echo "$SPEED_RESULT" | grep "Latency:" | awk '{print $2}')
            
            echo "  📥 Download: ${DOWNLOAD} Mbps"
            echo "  📤 Upload: ${UPLOAD} Mbps"
            echo "  ⚡ Ping: ${PING} ms"
            echo "${DOWNLOAD}|${UPLOAD}|${PING}"
            return
        fi
    fi
    
    # Fallback: use iperf or manual test
    echo "  ⚠️  Speedtest not working, using alternative..."
    
    # Simple download test
    DOWNLOAD=$(curl -s -w '%{speed_download}' -o /dev/null http://ipv4.download.thinkbroadband.com/10MB.zip 2>/dev/null | awk '{printf "%.2f", $1/1024/1024*8}')
    
    if [ -n "$DOWNLOAD" ] && [ "$DOWNLOAD" != "0.00" ]; then
        echo "  📥 Download: ${DOWNLOAD} Mbps (estimated)"
        echo "${DOWNLOAD}|0|0"
    else
        echo "  ❌ Speed test failed"
        echo "0|0|999"
    fi
}

echo "Testing channels with HT40+ (up to 300 Mbps)..."
echo ""

for CHAN in "${CHANNELS[@]}"; do
    echo "================================================"
    echo "Testing Channel $CHAN"
    echo "================================================"
    
    # Stop current hotspot
    sudo systemctl stop hostapd dnsmasq 2>/dev/null
    sudo pkill -9 hostapd 2>/dev/null
    sleep 2
    
    # Determine HT40 direction
    if [ "$CHAN" = "1" ]; then
        HT_CAP="[HT40+][SHORT-GI-20][SHORT-GI-40]"
    elif [ "$CHAN" = "6" ]; then
        HT_CAP="[HT40-][SHORT-GI-20][SHORT-GI-40]"
    elif [ "$CHAN" = "11" ]; then
        HT_CAP="[HT40-][SHORT-GI-20][SHORT-GI-40]"
    fi
    
    # Create optimized config for speed
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Speed-Test-Ch${CHAN}
hw_mode=g
channel=${CHAN}
country_code=ID

# 802.11n with HT40 for max speed
ieee80211n=1
ht_capab=${HT_CAP}

# QoS for better performance
wmm_enabled=1

# Security
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP

# Control interface
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# Stability (proven config)
beacon_int=100
dtim_period=2
max_num_sta=10
ap_max_inactivity=600
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0

# Rekey intervals
wpa_group_rekey=86400
wpa_ptk_rekey=600
eapol_key_index_workaround=1
ENDCONFIG
    
    # Setup interface (properly)
    echo "  Setting up interface..."
    sudo rfkill unblock wifi
    sudo ip link set wlp2s0 down
    sleep 1
    
    # Remove any existing config
    sudo /usr/sbin/iw dev wlp2s0 set type managed 2>/dev/null
    sudo ip addr flush dev wlp2s0
    
    # Bring up and configure
    sudo ip link set wlp2s0 up
    sleep 1
    
    # CRITICAL: Disable power saving
    sudo /usr/sbin/iw dev wlp2s0 set power_save off
    
    # Set to AP mode and assign IP
    sudo /usr/sbin/iw dev wlp2s0 set type __ap 2>/dev/null
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    sudo ip link set wlp2s0 up
    
    # Start hostapd
    echo "  Starting hostapd..."
    sudo systemctl start hostapd
    sleep 3
    
    if ! sudo systemctl is-active --quiet hostapd; then
        echo "  ❌ Failed to start hostapd"
        echo "$CHAN|FAILED|0|0|999" >> "$RESULTS_FILE"
        continue
    fi
    
    # Get interface info
    INFO=$(sudo /usr/sbin/iw dev wlp2s0 info)
    FREQ=$(echo "$INFO" | grep "channel" | awk '{print $2}')
    WIDTH=$(echo "$INFO" | grep "width:" | awk '{print $3}')
    
    echo "  📡 Channel: $CHAN"
    echo "  📡 Frequency: ${FREQ} MHz"
    echo "  📏 Width: ${WIDTH} MHz"
    echo ""
    
    # Start dnsmasq for DHCP
    sudo systemctl start dnsmasq
    sleep 2
    
    # Wait for client to connect
    echo "  Waiting 30s for client connection..."
    sleep 30
    
    # Check if client connected
    CLIENTS=$(sudo hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:" || echo 0)
    
    if [ "$CLIENTS" -gt 0 ]; then
        echo "  ✅ Client connected!"
        
        # Get client MAC
        CLIENT_MAC=$(sudo hostapd_cli all_sta 2>/dev/null | grep "^[0-9a-f][0-9a-f]:" | head -1)
        echo "  📱 Client: $CLIENT_MAC"
        echo ""
        
        # Run speedtest
        SPEED=$(get_speed)
        
        IFS='|' read -r DOWN UP PING <<< "$SPEED"
        echo "$CHAN|CONNECTED|$DOWN|$UP|$PING|$WIDTH" >> "$RESULTS_FILE"
    else
        echo "  ❌ No client connected"
        echo "$CHAN|NO_CLIENT|0|0|999|0" >> "$RESULTS_FILE"
    fi
    
    echo ""
    sleep 2
done

# Stop services
sudo systemctl stop hostapd dnsmasq

# Show results
echo "================================================"
echo "SPEED TEST RESULTS"
echo "================================================"
echo ""
echo "Channel | Status     | Download  | Upload    | Ping  | Width"
echo "--------|------------|-----------|-----------|-------|-------"

while IFS='|' read -r chan status down up ping width; do
    printf "%-7s | %-10s | %-9s | %-9s | %-5s | %s MHz\n" \
        "$chan" "$status" "${down} Mbps" "${up} Mbps" "${ping} ms" "$width"
done < "$RESULTS_FILE"

echo ""

# Find best channel
BEST_CHANNEL=$(grep "CONNECTED" "$RESULTS_FILE" | sort -t'|' -k3 -nr | head -1 | cut -d'|' -f1)
BEST_SPEED=$(grep "CONNECTED" "$RESULTS_FILE" | sort -t'|' -k3 -nr | head -1 | cut -d'|' -f3)

if [ -n "$BEST_CHANNEL" ]; then
    echo "🏆 BEST CHANNEL: $BEST_CHANNEL"
    echo "📥 Download Speed: $BEST_SPEED Mbps"
    echo ""
    echo "To apply this channel permanently:"
    echo "  sudo sed -i 's/^CHANNEL=.*/CHANNEL=$BEST_CHANNEL/' /opt/mihomo-gateway/scripts/hotspot.sh"
    echo ""
    
    # Save best config
    echo "Saving best configuration..."
    
    if [ "$BEST_CHANNEL" = "1" ]; then
        HT_CAP="[HT40+][SHORT-GI-20][SHORT-GI-40]"
    elif [ "$BEST_CHANNEL" = "6" ]; then
        HT_CAP="[HT40-][SHORT-GI-20][SHORT-GI-40]"
    elif [ "$BEST_CHANNEL" = "11" ]; then
        HT_CAP="[HT40-][SHORT-GI-20][SHORT-GI-40]"
    fi
    
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=${BEST_CHANNEL}
country_code=ID

# 802.11n with HT40 for max speed (up to 300 Mbps)
ieee80211n=1
ht_capab=${HT_CAP}

# QoS for better performance
wmm_enabled=1

# Security
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_pairwise=TKIP

# Control interface
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# Stability (proven working config)
beacon_int=100
dtim_period=2
max_num_sta=10
ap_max_inactivity=600
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0

# Rekey intervals
wpa_group_rekey=86400
wpa_ptk_rekey=600
eapol_key_index_workaround=1
ENDCONFIG
    
    echo "✅ Best config saved to /etc/hostapd/hostapd.conf"
    echo ""
    echo "Restart hotspot to apply:"
    echo "  sudo bash /opt/mihomo-gateway/scripts/hotspot.sh restart"
else
    echo "❌ No successful connection found"
fi

echo ""
echo "Full results saved to: $RESULTS_FILE"
