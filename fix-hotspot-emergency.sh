#!/bin/bash

# ============================================
# EMERGENCY FIX: Reset WiFi Interface Properly
# ============================================

echo "=== STEP 1: Stop semua proses hostapd ==="
sudo pkill -9 hostapd
sleep 2

echo "=== STEP 2: Reset wlp2s0 COMPLETELY ==="
# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Reset WiFi interface dari AP mode ke managed mode
sudo ip link set wlp2s0 down
sudo /usr/sbin/iw dev wlp2s0 set type managed
sudo ip link set wlp2s0 up
sleep 2

echo "=== STEP 3: Flush dan set ulang IP ==="
sudo ip addr flush dev wlp2s0
sleep 1
sudo ip link set wlp2s0 down
sleep 1
sudo ip link set wlp2s0 up
sleep 2

echo "=== STEP 4: Set ke AP mode dengan benar ==="
# Switch to AP mode
sudo /usr/sbin/iw dev wlp2s0 set type __ap
sleep 1

# Set IP
sudo ip addr add 192.168.1.1/24 dev wlp2s0
sleep 1

# Verify
echo ""
echo "=== Interface Status ==="
ip addr show wlp2s0
echo ""
/usr/sbin/iw dev wlp2s0 info
echo ""

echo "=== STEP 5: Start hostapd sebagai SERVICE ==="
sudo systemctl start hostapd
sleep 3

echo "=== STEP 6: Start dnsmasq ==="
sudo systemctl start dnsmasq
sleep 2

echo ""
echo "=== STEP 7: Verify semua jalan ==="
echo ""
echo "--- hostapd status ---"
sudo systemctl status hostapd --no-pager | head -15
echo ""
echo "--- dnsmasq status ---"
sudo systemctl status dnsmasq --no-pager | head -15
echo ""
echo "--- hostapd_cli status ---"
sudo hostapd_cli status
echo ""
echo "--- NAT rules ---"
sudo iptables -t nat -L POSTROUTING -n -v
echo ""
echo "=== DONE! Sekarang coba konek dari HP ==="
echo ""
echo "Jika masih disconnect, jalankan:"
echo "  sudo journalctl -u hostapd -f"
echo "Untuk lihat kenapa disconnect"
