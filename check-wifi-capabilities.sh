#!/bin/bash

echo "================================================"
echo "WiFi Capabilities Checker"
echo "================================================"
echo ""

# Get WiFi card info
echo "=== WiFi Hardware ==="
lspci | grep -i wireless
echo ""

# Get detailed capabilities
echo "=== Supported Bands & Channels ==="
/usr/sbin/iw list | grep -A 20 "Frequencies:"
echo ""

# Check if 5GHz supported
if /usr/sbin/iw list | grep -q "5180 MHz"; then
    echo "✅ 5GHz (802.11a/n/ac) SUPPORTED!"
    SUPPORTS_5GHZ=true
else
    echo "❌ 5GHz NOT supported (only 2.4GHz)"
    SUPPORTS_5GHZ=false
fi
echo ""

# Show supported modes
echo "=== Supported Modes ==="
/usr/sbin/iw list | grep -A 10 "Supported interface modes:"
echo ""

# Show HT/VHT capabilities
echo "=== Speed Capabilities ==="
if /usr/sbin/iw list | grep -q "VHT Capabilities"; then
    echo "✅ 802.11ac (VHT) - up to 867 Mbps"
fi

if /usr/sbin/iw list | grep -q "HT Capabilities"; then
    echo "✅ 802.11n (HT40) - up to 300 Mbps"
fi

echo "✅ 802.11g - up to 54 Mbps"
echo ""

# Get all available channels
echo "=== Available Channels ==="
echo ""
echo "2.4GHz Channels:"
/usr/sbin/iw list | grep -E "^\s+\* (24[0-9]{2}|241[0-4]) MHz" | awk '{print $2, $3, $4, $5, $6}'
echo ""

if [ "$SUPPORTS_5GHZ" = true ]; then
    echo "5GHz Channels:"
    /usr/sbin/iw list | grep -E "^\s+\* (5[0-9]{3}) MHz" | awk '{print $2, $3, $4, $5, $6}'
    echo ""
fi

# Current interface status
echo "=== Current wlp2s0 Status ==="
/usr/sbin/iw dev wlp2s0 info
echo ""

# Recommendation
echo "================================================"
echo "RECOMMENDATIONS"
echo "================================================"
echo ""

if [ "$SUPPORTS_5GHZ" = true ]; then
    cat << 'EOF'
🚀 Your WiFi supports 5GHz - MUCH FASTER!

Speed comparison:
  2.4GHz (g):     ~54 Mbps  (crowded, interference)
  2.4GHz (n):     ~150 Mbps (HT20, more stable)
  5GHz (n):       ~300 Mbps (HT40, less interference)
  5GHz (ac):      ~867 Mbps (VHT80, best!)

Best 5GHz channels for Indonesia:
  - Channel 36-48  (5.180-5.240 GHz) - Legal, less crowded
  - Channel 149-165 (5.745-5.825 GHz) - Legal, fastest
  
Best 2.4GHz channels:
  - Channel 1, 6, 11 (non-overlapping)

Want to test ALL channels including 5GHz?
Run: bash test-all-channels-full.sh

EOF
else
    cat << 'EOF'
📡 Your WiFi only supports 2.4GHz

Best channels for speed:
  - Channel 1  (least interference usually)
  - Channel 6  (middle, most compatible)
  - Channel 11 (least interference usually)

Channels to AVOID:
  - 2-5, 7-10, 12-13 (overlap with others)

For faster speeds, consider:
  - USB WiFi adapter with 5GHz (AC1200/AC1300)
  - Examples: TP-Link Archer T3U, T4U
  - Cost: ~$15-25, can reach 867 Mbps on 5GHz

EOF
fi

# Generate test script if 5GHz supported
if [ "$SUPPORTS_5GHZ" = true ]; then
    echo "Generating full channel test script..."
    
    cat > test-all-channels-full.sh << 'EOFSCRIPT'
#!/bin/bash

echo "Testing ALL channels (2.4GHz + 5GHz) with PROVEN config"
echo ""

# 2.4GHz channels (most compatible)
CHANNELS_24=(1 6 11)

# 5GHz channels (Indonesia legal)
CHANNELS_5=(36 40 44 48 149 153 157 161 165)

RESULTS_FILE="/tmp/channel_test_full.txt"
> "$RESULTS_FILE"

# Disable power saving
sudo /usr/sbin/iw dev wlp2s0 set power_save off 2>/dev/null

# Test 2.4GHz
for CHAN in "${CHANNELS_24[@]}"; do
    echo "Testing 2.4GHz Channel $CHAN..."
    
    sudo systemctl stop hostapd
    sudo pkill -9 hostapd
    sleep 2
    
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Speed-Test-2G-Ch${CHAN}
hw_mode=g
channel=${CHAN}
country_code=ID
ieee80211n=1
ht_capab=[HT20]
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ctrl_interface=/var/run/hostapd
beacon_int=100
dtim_period=2
ap_max_inactivity=600
disassoc_low_ack=0
ENDCONFIG
    
    sudo ip link set wlp2s0 down
    sudo /usr/sbin/iw dev wlp2s0 set type managed
    sudo ip link set wlp2s0 up
    sudo ip addr flush dev wlp2s0
    sudo /usr/sbin/iw dev wlp2s0 set power_save off
    sudo /usr/sbin/iw dev wlp2s0 set type __ap
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    
    START=$(date +%s)
    sudo systemctl start hostapd
    sleep 3
    
    if sudo systemctl is-active --quiet hostapd; then
        echo "  Monitoring 15s (connect now)..."
        sleep 15
        
        CLIENTS=$(sudo hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:" || echo 0)
        END=$(date +%s)
        
        if [ "$CLIENTS" -gt 0 ]; then
            echo "  ✅ Connected in $((END-START))s"
            echo "2.4G|$CHAN|STABLE|$((END-START))" >> "$RESULTS_FILE"
        else
            echo "  ❌ No connection"
            echo "2.4G|$CHAN|NO_CONN|0" >> "$RESULTS_FILE"
        fi
    else
        echo "  ❌ Failed to start"
        echo "2.4G|$CHAN|FAILED|0" >> "$RESULTS_FILE"
    fi
    
    echo ""
done

# Test 5GHz
for CHAN in "${CHANNELS_5[@]}"; do
    echo "Testing 5GHz Channel $CHAN..."
    
    sudo systemctl stop hostapd
    sudo pkill -9 hostapd
    sleep 2
    
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Speed-Test-5G-Ch${CHAN}
hw_mode=a
channel=${CHAN}
country_code=ID
ieee80211n=1
ieee80211ac=1
ht_capab=[HT40+]
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=$((CHAN + 6))
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ctrl_interface=/var/run/hostapd
beacon_int=100
dtim_period=2
ap_max_inactivity=600
disassoc_low_ack=0
ENDCONFIG
    
    sudo ip link set wlp2s0 down
    sudo /usr/sbin/iw dev wlp2s0 set type managed
    sudo ip link set wlp2s0 up
    sudo ip addr flush dev wlp2s0
    sudo /usr/sbin/iw dev wlp2s0 set power_save off
    sudo /usr/sbin/iw dev wlp2s0 set type __ap
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    
    START=$(date +%s)
    sudo systemctl start hostapd
    sleep 3
    
    if sudo systemctl is-active --quiet hostapd; then
        echo "  Monitoring 15s (connect now)..."
        sleep 15
        
        CLIENTS=$(sudo hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:" || echo 0)
        END=$(date +%s)
        
        if [ "$CLIENTS" -gt 0 ]; then
            echo "  ✅ Connected in $((END-START))s"
            echo "5G|$CHAN|STABLE|$((END-START))" >> "$RESULTS_FILE"
        else
            echo "  ❌ No connection"
            echo "5G|$CHAN|NO_CONN|0" >> "$RESULTS_FILE"
        fi
    else
        echo "  ❌ Failed to start"
        echo "5G|$CHAN|FAILED|0" >> "$RESULTS_FILE"
    fi
    
    echo ""
done

# Show results
echo "================================================"
echo "RESULTS SUMMARY"
echo "================================================"
echo ""
echo "Band | Channel | Status  | Speed Potential"
echo "-----|---------|---------|----------------"

grep "2.4G" "$RESULTS_FILE" | while IFS='|' read band chan status time; do
    SPEED="~150 Mbps (HT20)"
    printf "%-4s | %-7s | %-7s | %s\n" "$band" "$chan" "$status" "$SPEED"
done

grep "5G" "$RESULTS_FILE" | while IFS='|' read band chan status time; do
    SPEED="~867 Mbps (VHT80)"
    printf "%-4s | %-7s | %-7s | %s\n" "$band" "$chan" "$status" "$SPEED"
done

echo ""
echo "Best 2.4GHz channel:"
grep "2.4G.*STABLE" "$RESULTS_FILE" | head -1 | cut -d'|' -f2

echo "Best 5GHz channel:"
grep "5G.*STABLE" "$RESULTS_FILE" | head -1 | cut -d'|' -f2

echo ""
echo "💡 5GHz is MUCH FASTER but shorter range"
echo "💡 2.4GHz is slower but better wall penetration"
EOFSCRIPT
    
    chmod +x test-all-channels-full.sh
    echo "✅ Generated: test-all-channels-full.sh"
fi

echo ""
