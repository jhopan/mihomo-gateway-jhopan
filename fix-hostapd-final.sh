#!/bin/bash

# ============================================
# FINAL FIX: Ultra-compatible hostapd config
# ============================================

echo "=== FINAL FIX: Authentication timeout issue ==="
echo ""
echo "Problem detected:"
echo "  'deauthenticated due to inactivity (timer DEAUTH/REMOVE)'"
echo "  Client deauth BEFORE completing handshake!"
echo ""
echo "Root cause: Driver bug with certain WMM/QoS parameters"
echo ""

# Stop everything
echo "=== Step 1: Stop services ==="
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sleep 2

# Kill any remaining hostapd
sudo pkill -9 hostapd
sleep 1

echo ""
echo "=== Step 2: Apply ULTRA-COMPATIBLE config ==="
echo ""

sudo bash -c 'cat > /etc/hostapd/hostapd.conf << EOF
# ============================================
# ULTRA-COMPATIBLE CONFIG
# ============================================

# Basic interface
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6

# Security - Standard WPA2
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP

# Basic settings
country_code=ID
ieee80211n=1
auth_algs=1
ignore_broadcast_ssid=0

# Control interface
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# ============================================
# CRITICAL FIX: Disable ALL QoS/WMM features
# ============================================
# WMM causes "deauthenticated due to inactivity"
# on certain WiFi chipsets (like yours)
wmm_enabled=0

# ============================================
# AUTHENTICATION TIMEOUTS - VERY GENEROUS
# ============================================

# Increase auth/assoc timeouts (prevent premature deauth)
ap_max_inactivity=0

# CRITICAL: Disable station inactivity timeout
# This is DIFFERENT from ap_max_inactivity!
# Controls authentication phase timeout
max_listen_interval=65535

# Disable low ACK disconnect
disassoc_low_ack=0

# Skip all inactivity checks
skip_inactivity_poll=1

# Allow all clients (no isolation)
ap_isolate=0

# ============================================
# BEACON/TIMING - Standard values
# ============================================
beacon_int=100
dtim_period=2

# Maximum clients
max_num_sta=10

# ============================================
# DISABLE POWER MANAGEMENT
# ============================================
# Don't kick clients in power saving mode
ieee80211d=0
EOF'

echo "Config written to /etc/hostapd/hostapd.conf"
echo ""

# Reset WiFi interface completely
echo "=== Step 3: Reset WiFi interface ==="
sudo ip link set wlp2s0 down
sudo /usr/sbin/iw dev wlp2s0 set type managed
sudo ip link set wlp2s0 up
sleep 2

sudo ip addr flush dev wlp2s0
sudo ip link set wlp2s0 down
sleep 1
sudo ip link set wlp2s0 up
sleep 2

# Set to AP mode
sudo /usr/sbin/iw dev wlp2s0 set type __ap 2>/dev/null
sleep 1

# Set IP
sudo ip addr add 192.168.1.1/24 dev wlp2s0
sleep 1

echo ""
echo "=== Step 4: Start services ==="

# Start hostapd
sudo systemctl start hostapd
sleep 3

# Start dnsmasq
sudo systemctl start dnsmasq
sleep 2

echo ""
echo "=== Step 5: Verify ==="
echo ""

sudo systemctl status hostapd --no-pager | head -20
echo ""
echo "--- hostapd_cli status ---"
sudo hostapd_cli status | head -30
echo ""

echo "=== Step 6: Monitor for deauth errors ==="
echo ""
echo "Sekarang coba konek dari HP, saya akan monitor log..."
echo "Tekan Ctrl+C kalau sudah berhasil konek dan internet jalan"
echo ""
sleep 3

sudo journalctl -u hostapd -f -n 50
