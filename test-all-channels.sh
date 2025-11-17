#!/bin/bash

echo "================================================"
echo "AUTO CHANNEL SCANNER - Find Best Channel!"
echo "================================================"
echo ""
echo "Testing ALL 2.4GHz channels with PROVEN config"
echo "Will find the channel with best performance!"
echo ""

# All 2.4GHz channels
CHANNELS=(1 2 3 4 5 6 7 8 9 10 11 12 13)
RESULTS_FILE="/tmp/channel_test_results.txt"
> "$RESULTS_FILE"

# Disable power saving first
sudo /usr/sbin/iw dev wlp2s0 set power_save off 2>/dev/null || true

for CHAN in "${CHANNELS[@]}"; do
    echo ""
    echo "========================================"
    echo "Testing Channel $CHAN (2.4GHz)"
    echo "========================================"
    
    # Stop services
    sudo systemctl stop hostapd 2>/dev/null
    sudo pkill -9 hostapd 2>/dev/null
    sleep 2
    
    # Create config for this channel (using PROVEN settings)
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Test-Ch${CHAN}
hw_mode=g
channel=${CHAN}
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
wpa_group_rekey=86400
wpa_ptk_rekey=600
eapol_key_index_workaround=1
ENDCONFIG
    
    # Reset interface
    sudo ip link set wlp2s0 down
    sleep 1
    sudo /usr/sbin/iw dev wlp2s0 set type managed
    sudo ip link set wlp2s0 up
    sleep 2
    sudo ip addr flush dev wlp2s0
    sudo /usr/sbin/iw dev wlp2s0 set power_save off
    sudo /usr/sbin/iw dev wlp2s0 set type __ap
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    sleep 1
    
    # Start hostapd
    START_TIME=$(date +%s)
    sudo systemctl start hostapd
    sleep 3
    
    # Check if started successfully
    if sudo systemctl is-active --quiet hostapd; then
        echo "✅ Channel $CHAN: hostapd started"
        
        # Get signal quality info
        FREQ=$(/usr/sbin/iw dev wlp2s0 info | grep channel | awk '{print $5}' | tr -d ')')
        TX_POWER=$(sudo /usr/sbin/iw dev wlp2s0 info | grep txpower | awk '{print $2" "$3}')
        
        echo "   Frequency: $FREQ MHz"
        echo "   TX Power: $TX_POWER"
        echo ""
        echo "   Network: Test-Ch${CHAN}"
        echo "   Password: mihomo2024"
        echo ""
        echo "   Monitoring for 20 seconds..."
        echo "   (Try connecting from phone!)"
        echo ""
        
        # Monitor for connections
        CONNECTED=0
        TIMEOUT_TIME=$((START_TIME + 20))
        
        while [ $(date +%s) -lt $TIMEOUT_TIME ]; do
            CLIENT_COUNT=$(sudo hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:" || echo 0)
            
            if [ "$CLIENT_COUNT" -gt 0 ]; then
                CONNECTED=1
                END_TIME=$(date +%s)
                CONNECT_TIME=$((END_TIME - START_TIME))
                
                echo "   🎉 CLIENT CONNECTED in ${CONNECT_TIME}s!"
                
                # Get client info
                CLIENT_MAC=$(sudo hostapd_cli all_sta 2>/dev/null | grep "^[0-9a-f]" | head -1)
                echo "   Client MAC: $CLIENT_MAC"
                
                # Test stability for 10 more seconds
                echo "   Testing stability for 10 seconds..."
                sleep 10
                
                STILL_CONNECTED=$(sudo hostapd_cli all_sta 2>/dev/null | grep -c "$CLIENT_MAC" || echo 0)
                
                if [ "$STILL_CONNECTED" -gt 0 ]; then
                    echo "   ✅ Connection STABLE!"
                    echo "$CHAN|STABLE|$CONNECT_TIME|$FREQ|$TX_POWER" >> "$RESULTS_FILE"
                else
                    echo "   ⚠️  Connection dropped"
                    echo "$CHAN|DROPPED|$CONNECT_TIME|$FREQ|$TX_POWER" >> "$RESULTS_FILE"
                fi
                
                break
            fi
            
            sleep 1
        done
        
        if [ "$CONNECTED" -eq 0 ]; then
            echo "   ❌ No connection in 20 seconds"
            echo "$CHAN|NO_CONN|0|$FREQ|$TX_POWER" >> "$RESULTS_FILE"
        fi
        
    else
        echo "❌ Channel $CHAN: hostapd FAILED to start"
        echo "$CHAN|FAILED|0|0|0" >> "$RESULTS_FILE"
    fi
    
    echo ""
    read -p "Press Enter for next channel (or Ctrl+C to stop)..." -t 3 || true
done

# Show results
echo ""
echo "================================================"
echo "TEST RESULTS SUMMARY"
echo "================================================"
echo ""

if [ -f "$RESULTS_FILE" ]; then
    echo "Channel | Status  | Connect Time | Frequency | TX Power"
    echo "--------|---------|--------------|-----------|----------"
    
    while IFS='|' read -r chan status time freq power; do
        printf "%-7s | %-7s | %-12s | %-9s | %s\n" "$chan" "$status" "${time}s" "$freq MHz" "$power"
    done < "$RESULTS_FILE"
    
    echo ""
    echo "Best channels (STABLE connections):"
    grep "STABLE" "$RESULTS_FILE" | cut -d'|' -f1 | tr '\n' ' '
    echo ""
    echo ""
    
    # Find best channel (STABLE with shortest connect time)
    BEST_CHANNEL=$(grep "STABLE" "$RESULTS_FILE" | sort -t'|' -k3 -n | head -1 | cut -d'|' -f1)
    
    if [ -n "$BEST_CHANNEL" ]; then
        echo "🏆 RECOMMENDED CHANNEL: $BEST_CHANNEL"
        echo ""
        echo "To use this channel permanently, run:"
        echo "  sudo sed -i 's/channel=.*/channel=$BEST_CHANNEL/' /etc/hostapd/hostapd.conf"
        echo "  sudo systemctl restart hostapd"
    else
        echo "⚠️  No stable channels found"
        echo ""
        echo "Try:"
        echo "  1. Move closer to WiFi router (reduce interference)"
        echo "  2. Use 5GHz if your card supports it"
        echo "  3. Consider USB WiFi adapter"
    fi
else
    echo "No results file found"
fi

echo ""
echo "Full results saved to: $RESULTS_FILE"
echo ""
