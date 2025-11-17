#!/bin/bash

cat << 'EOF'
================================================
ROOT CAUSE FOUND: MAC ADDRESS RANDOMIZATION!
================================================

Problem Detected:
-----------------
Multiple different MAC addresses seen:
  - de:1c:8c:1f:11:bf
  - 78:d8:40:f4:1a:f7
  - a2:cd:c2:d9:08:58
  - 2a:16:27:40:64:7c
  - 7e:de:3e:3a:a1:f2

This is MAC randomization (privacy feature)!

Why it causes authentication failure:
1. Phone generates random MAC address
2. Starts connecting to WiFi
3. Phone changes MAC again (randomization)
4. hostapd thinks client disappeared
5. Deauthenticates → Loop forever!

================================================
SOLUTION: Disable MAC Randomization on Phone
================================================

📱 For Android:
---------------
1. Go to: Settings → WiFi
2. Long press "Mihomo-Gateway" → Modify Network
3. Advanced Options → Privacy
4. Change from "Randomized MAC" to "Device MAC"
5. Save and reconnect

📱 For Android 10+:
-------------------
1. Settings → Network & Internet → WiFi
2. Tap "Mihomo-Gateway"
3. Tap gear icon (settings)
4. Privacy → Use device MAC
5. Reconnect

📱 For iPhone/iOS:
------------------
1. Settings → WiFi
2. Tap (i) next to "Mihomo-Gateway"
3. Turn OFF "Private Wi-Fi Address"
4. Reconnect

================================================
ALTERNATIVE: Accept All MACs (Less Secure)
================================================

We can configure hostapd to accept ANY MAC address
and handle the randomization issue.

EOF

read -p "Do you want to apply workaround config now? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Applying MAC randomization workaround..."
    
    # Stop services
    sudo systemctl stop hostapd
    sudo systemctl stop dnsmasq
    sleep 2
    
    # Config that handles MAC randomization better
    sudo tee /etc/hostapd/hostapd.conf > /dev/null << 'ENDCONFIG'
interface=wlp2s0
driver=nl80211
ssid=Mihomo-Gateway
hw_mode=g
channel=6
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
ap_max_inactivity=0
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0
macaddr_acl=0
max_num_sta=255
wpa_group_rekey=0
wpa_ptk_rekey=0
eapol_key_index_workaround=1
ieee80211w=0
ENDCONFIG
    
    echo "Config applied with MAC randomization tolerance"
    
    # Reset interface
    sudo ip link set wlp2s0 down
    sleep 1
    sudo ip link set wlp2s0 up
    sleep 2
    sudo ip addr flush dev wlp2s0
    sudo /usr/sbin/iw dev wlp2s0 set type __ap
    sudo ip addr add 192.168.1.1/24 dev wlp2s0
    sleep 1
    
    # Start services
    sudo systemctl start hostapd
    sleep 3
    sudo systemctl start dnsmasq
    sleep 2
    
    echo ""
    echo "=== Status ==="
    sudo systemctl status hostapd --no-pager | head -15
    echo ""
    
    echo "✅ Workaround applied!"
    echo ""
    echo "BUT BEST SOLUTION: Disable MAC randomization on phone!"
    echo ""
    
    sudo journalctl -u hostapd -f
else
    echo ""
    echo "Please disable MAC randomization on your phone first,"
    echo "then try connecting again."
fi
