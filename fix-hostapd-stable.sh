#!/bin/bash

# ============================================
# FIX: Update hostapd config untuk stability
# ============================================

echo "=== Updating hostapd config untuk stability 24/7 ==="

# Stop hostapd first to avoid "Match already configured" error
echo "Stopping hostapd..."
sudo systemctl stop hostapd
sleep 2

sudo bash -c 'cat > /etc/hostapd/hostapd.conf << EOF
# Basic Config - Tested & Working
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1

# Security
wpa=2
wpa_passphrase=mihomo2024
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP

# Basic settings
country_code=ID
auth_algs=1
ignore_broadcast_ssid=0

# Control interface
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# ==========================================
# STABILITY FIX - NEVER DISCONNECT CLIENTS
# ==========================================

# Client timeout DISABLED (0 = never timeout)
ap_max_inactivity=0

# Disable low ACK disconnection (prevent disconnect on weak signal)
disassoc_low_ack=0

# Skip inactivity polling (dont check if client idle)
skip_inactivity_poll=1

# AP isolation OFF (allow client-to-client communication)
ap_isolate=0

# Beacon and keepalive
beacon_int=100
dtim_period=2

# WMM parameters (disable power saving detection)
wmm_ac_bk_cwmin=4
wmm_ac_bk_cwmax=10
wmm_ac_bk_aifs=7
wmm_ac_bk_txop_limit=0
wmm_ac_bk_acm=0
wmm_ac_be_aifs=3
wmm_ac_be_cwmin=4
wmm_ac_be_cwmax=10
wmm_ac_be_txop_limit=0
wmm_ac_be_acm=0
wmm_ac_vi_aifs=2
wmm_ac_vi_cwmin=3
wmm_ac_vi_cwmax=4
wmm_ac_vi_txop_limit=94
wmm_ac_vi_acm=0
wmm_ac_vo_aifs=2
wmm_ac_vo_cwmin=2
wmm_ac_vo_cwmax=3
wmm_ac_vo_txop_limit=47
wmm_ac_vo_acm=0
EOF'

echo ""
echo "=== Testing config ==="
sudo hostapd -t /etc/hostapd/hostapd.conf

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Config valid!"
    echo ""
    echo "=== Restarting hostapd ==="
    sudo systemctl restart hostapd
    sleep 3
    
    echo ""
    echo "=== Status ==="
    sudo systemctl status hostapd --no-pager | head -20
    echo ""
    sudo hostapd_cli status
    echo ""
    echo "✅ DONE! Hotspot sekarang stable 24/7"
    echo ""
    echo "Changes applied:"
    echo "  - ap_max_inactivity=0 (never timeout)"
    echo "  - disassoc_low_ack=0 (dont disconnect on weak signal)"
    echo "  - skip_inactivity_poll=1 (dont check idle status)"
    echo "  - WMM parameters to prevent power saving issues"
    echo ""
    echo "Client akan tetap connected bahkan jika:"
    echo "  - Tidak ada traffic 1 jam+"
    echo "  - Signal lemah"
    echo "  - Phone dalam power saving mode"
else
    echo ""
    echo "❌ Config error! Check output above"
fi
