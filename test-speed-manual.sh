#!/bin/bash

echo "================================================"
echo "Manual Channel Speed Test"
echo "================================================"
echo ""
echo "Kamu akan test 3 channel secara manual:"
echo "  1. Connect ke hotspot"
echo "  2. Buka speedtest.net di HP"
echo "  3. Catat hasilnya"
echo ""

CHANNELS=(1 6 11)

for CHAN in "${CHANNELS[@]}"; do
    echo "================================================"
    echo "CHANNEL $CHAN"
    echo "================================================"
    
    # Stop services
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
    
    # Create config
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=SpeedTest-Ch${CHAN}
hw_mode=g
channel=${CHAN}
country_code=ID

# 802.11n with HT40 for max speed
ieee80211n=1
ht_capab=${HT_CAP}

# QoS
wmm_enabled=1

# Security
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP

# Control
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# Stability
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
    
    # Setup interface
    sudo rfkill unblock wifi
    sudo ip link set wlp2s0 down
    sleep 1
    sudo ip addr flush dev wlp2s0
    sudo ip link set wlp2s0 up
    sudo /usr/sbin/iw dev wlp2s0 set power_save off
    sudo /usr/sbin/iw dev wlp2s0 set type __ap 2>/dev/null
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    sudo ip link set wlp2s0 up
    
    # Start hostapd
    sudo systemctl start hostapd
    sleep 3
    
    if ! sudo systemctl is-active --quiet hostapd; then
        echo "❌ Failed to start hostapd!"
        sudo journalctl -u hostapd -n 20 --no-pager
        continue
    fi
    
    # Setup NAT (untuk internet)
    USB_IFACE=$(ip link show | grep -E "enx|usb" | grep "state UP" | awk -F: '{print $2}' | tr -d ' ' | head -1)
    if [ -z "$USB_IFACE" ]; then
        USB_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    fi
    
    echo "USB Interface: $USB_IFACE"
    
    sudo iptables -t nat -F
    sudo iptables -t nat -A POSTROUTING -o $USB_IFACE -j MASQUERADE
    sudo iptables -A FORWARD -i wlp2s0 -o $USB_IFACE -j ACCEPT
    sudo iptables -A FORWARD -i $USB_IFACE -o wlp2s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    # Start DHCP
    sudo systemctl start dnsmasq
    sleep 2
    
    # Show info
    INFO=$(sudo /usr/sbin/iw dev wlp2s0 info)
    FREQ=$(echo "$INFO" | grep "channel" | head -1 | awk '{print $2}')
    WIDTH=$(echo "$INFO" | grep "width:" | awk '{print $3}')
    
    echo ""
    echo "✅ Hotspot started!"
    echo "📡 SSID: SpeedTest-Ch${CHAN}"
    echo "🔑 Password: mihomo2024"
    echo "📻 Channel: $CHAN"
    echo "📡 Frequency: ${FREQ} MHz"
    echo "📏 Width: ${WIDTH} MHz"
    echo ""
    echo "INSTRUKSI:"
    echo "1. MATIKAN MAC RANDOMIZATION di HP!"
    echo "2. Connect ke: SpeedTest-Ch${CHAN}"
    echo "3. Buka: https://speedtest.net"
    echo "4. Klik GO dan tunggu selesai"
    echo "5. Catat: Download, Upload, Ping"
    echo ""
    
    read -p "Tekan ENTER setelah speedtest selesai..." dummy
    
    # Show connected clients
    echo ""
    echo "Connected clients:"
    sudo hostapd_cli all_sta 2>/dev/null | grep "^[0-9a-f][0-9a-f]:" | head -5
    
    echo ""
    read -p "Download (Mbps): " DOWN
    read -p "Upload (Mbps): " UP
    read -p "Ping (ms): " PING
    
    echo "$CHAN|$DOWN|$UP|$PING|$WIDTH" >> /tmp/manual_speed_test.txt
    
    echo ""
    echo "✅ Hasil dicatat!"
    echo ""
done

# Stop services
sudo systemctl stop hostapd dnsmasq

# Show results
echo "================================================"
echo "HASIL SPEED TEST"
echo "================================================"
echo ""
echo "Channel | Download  | Upload    | Ping  | Width"
echo "--------|-----------|-----------|-------|-------"

while IFS='|' read -r chan down up ping width; do
    printf "%-7s | %-9s | %-9s | %-5s | %s MHz\n" \
        "$chan" "${down} Mbps" "${up} Mbps" "${ping} ms" "$width"
done < /tmp/manual_speed_test.txt

echo ""

# Find best
BEST=$(sort -t'|' -k2 -nr /tmp/manual_speed_test.txt | head -1)
BEST_CHAN=$(echo "$BEST" | cut -d'|' -f1)
BEST_DOWN=$(echo "$BEST" | cut -d'|' -f2)
BEST_UP=$(echo "$BEST" | cut -d'|' -f3)
BEST_PING=$(echo "$BEST" | cut -d'|' -f4)

echo "🏆 CHANNEL TERBAIK: $BEST_CHAN"
echo "📥 Download: $BEST_DOWN Mbps"
echo "📤 Upload: $BEST_UP Mbps"
echo "⚡ Ping: $BEST_PING ms"
echo ""

# Apply best channel
echo "Applying best channel..."

if [ "$BEST_CHAN" = "1" ]; then
    HT_CAP="[HT40+][SHORT-GI-20][SHORT-GI-40]"
elif [ "$BEST_CHAN" = "6" ]; then
    HT_CAP="[HT40-][SHORT-GI-20][SHORT-GI-40]"
elif [ "$BEST_CHAN" = "11" ]; then
    HT_CAP="[HT40-][SHORT-GI-20][SHORT-GI-40]"
fi

sudo tee /etc/hostapd/hostapd.conf > /dev/null << ENDCONFIG
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=${BEST_CHAN}
country_code=ID

# 802.11n with HT40 for max speed
ieee80211n=1
ht_capab=${HT_CAP}

# QoS
wmm_enabled=1

# Security
auth_algs=1
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_pairwise=TKIP

# Control
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
wpa_group_rekey=86400
wpa_ptk_rekey=600
eapol_key_index_workaround=1
ENDCONFIG

echo "✅ Config tersimpan dengan channel $BEST_CHAN"
echo ""
echo "Restart hotspot:"
echo "  sudo bash /opt/mihomo-gateway/scripts/hotspot.sh restart"
