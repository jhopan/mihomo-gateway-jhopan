#!/bin/bash

echo "=== DIAGNOSTIC: Check current hostapd config ==="
echo ""

echo "1. Config file content:"
echo "------------------------"
sudo cat /etc/hostapd/hostapd.conf
echo ""
echo ""

echo "2. What hostapd service is using:"
echo "----------------------------------"
sudo systemctl cat hostapd | grep -A5 ExecStart
echo ""
echo ""

echo "3. Current hostapd status:"
echo "--------------------------"
sudo hostapd_cli status
echo ""
echo ""

echo "4. WiFi interface info:"
echo "-----------------------"
/usr/sbin/iw dev wlp2s0 info
echo ""
echo ""

echo "5. Check for conflicting processes:"
echo "------------------------------------"
ps aux | grep -E "hostapd|wpa_supplicant|NetworkManager" | grep -v grep
echo ""
echo ""

echo "6. Kernel module info:"
echo "----------------------"
lsmod | grep -E "cfg80211|mac80211|iwlwifi|ath|rtl"
echo ""
echo ""

echo "7. Recent hostapd logs (last 50 lines):"
echo "----------------------------------------"
sudo journalctl -u hostapd -n 50 --no-pager
