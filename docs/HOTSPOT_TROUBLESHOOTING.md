# 🛠️ Hotspot Troubleshooting Guide

## 🔍 Common Issues & Solutions

### Issue 1: Client Disconnects After Few Minutes

**Symptoms:**
- Phone/device connects successfully
- After 2-5 minutes, connection drops
- Cannot reconnect without restarting hotspot

**Causes:**
- WiFi power management enabled
- Driver putting interface to sleep
- Weak signal or interference

**Solutions:**

```bash
# 1. Check if power management is disabled
iw dev wlp2s0 get power_save
# Should show: "Power save: off"

# 2. Manually disable if needed
sudo iw dev wlp2s0 set power_save off
sudo iwconfig wlp2s0 power off

# 3. Check interface status
ip link show wlp2s0
# Should show: "state UP"

# 4. Check hostapd clients
sudo hostapd_cli all_sta
# Shows connected clients and signal strength

# 5. Enable stability monitor
sudo cp scripts/hotspot-stability-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable hotspot-stability-monitor
sudo systemctl start hotspot-stability-monitor

# 6. Check monitor logs
sudo journalctl -u hotspot-stability-monitor -f
```

---

### Issue 2: Cannot Connect to Hotspot

**Symptoms:**
- SSID visible but authentication fails
- "Obtaining IP address..." stuck forever
- Wrong password error (but password is correct)

**Causes:**
- hostapd not running properly
- Channel interference
- DHCP server issue

**Solutions:**

```bash
# 1. Check services status
sudo systemctl status hostapd
sudo systemctl status dnsmasq

# 2. Check hostapd config
sudo cat /etc/hostapd/hostapd.conf | grep -E "interface|channel|ssid|wpa_passphrase"

# 3. Test hostapd manually
sudo systemctl stop hostapd
sudo hostapd -dd /etc/hostapd/hostapd.conf
# Press Ctrl+C after seeing errors, then:
sudo systemctl start hostapd

# 4. Try different channel
sudo bash scripts/hotspot.sh stop
sudo nano /etc/hostapd/hostapd.conf
# Change: channel=11 to channel=1 or channel=6
sudo bash scripts/hotspot.sh start

# 5. Check DHCP leases
cat /var/lib/misc/dnsmasq.leases
# Should show connected clients

# 6. Clear old leases
sudo rm /var/lib/misc/dnsmasq.leases
sudo systemctl restart dnsmasq
```

---

### Issue 3: Hotspot Stops After System Sleep/Suspend

**Symptoms:**
- Hotspot works fine initially
- After laptop sleep/suspend, hotspot stops
- Need to manually restart

**Solutions:**

```bash
# 1. Create systemd sleep hook
sudo nano /etc/systemd/system/hotspot-resume.service

# Add:
[Unit]
Description=Restart Hotspot After Resume
After=suspend.target

[Service]
Type=oneshot
ExecStart=/opt/mihomo-gateway/scripts/hotspot.sh restart

[Install]
WantedBy=suspend.target

# Save and enable:
sudo systemctl daemon-reload
sudo systemctl enable hotspot-resume

# 2. Prevent WiFi interface from sleeping
sudo nano /etc/NetworkManager/conf.d/disable-wifi-powersave.conf

# Add:
[connection]
wifi.powersave = 2

# Restart NetworkManager:
sudo systemctl restart NetworkManager

# 3. Disable laptop suspend when lid closed (optional)
sudo nano /etc/systemd/logind.conf
# Change: HandleLidSwitch=ignore
sudo systemctl restart systemd-logind
```

---

### Issue 4: Slow Speed or High Latency

**Symptoms:**
- Connection works but very slow
- High ping times (>100ms)
- Downloads timeout

**Causes:**
- Channel interference
- Weak signal
- NAT/routing issue

**Solutions:**

```bash
# 1. Check signal strength
sudo iw dev wlp2s0 station dump
# Look for "signal:" value (should be > -70 dBm)

# 2. Scan for best channel
sudo bash scripts/smart-channel.sh wlp2s0 scan
# Shows channel usage and recommendations

# 3. Test different channels
for ch in 1 6 11; do
    echo "Testing channel $ch..."
    sudo bash scripts/hotspot.sh stop
    sudo sed -i "s/^channel=.*/channel=$ch/" /etc/hostapd/hostapd.conf
    sudo bash scripts/hotspot.sh start
    sleep 5
    # Test ping from client here
done

# 4. Check NAT routing
sudo iptables -t nat -L POSTROUTING -v -n
# Should show MASQUERADE rule for your internet interface

# 5. Check bandwidth
# On client device, run speedtest
# Or use: iperf3 -s (on gateway) / iperf3 -c 192.168.1.1 (on client)

# 6. Optimize hostapd
sudo nano /etc/hostapd/hostapd.conf
# Try changing:
# wmm_enabled=0 → wmm_enabled=1
# Add: ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40]
sudo bash scripts/hotspot.sh restart
```

---

### Issue 5: Interface Name Changes (USB Tethering)

**Symptoms:**
- After USB replug: `enx365a03849d07` becomes `enx...something else`
- Hotspot stops working
- Need to reconfigure

**Solutions:**

```bash
# 1. The script already auto-detects! Just restart:
sudo bash scripts/hotspot.sh restart

# 2. Check detected interfaces
ip link show | grep enx

# 3. Verify auto-detection works
sudo bash scripts/detect-interfaces.sh detect
cat /tmp/mihomo-interfaces.conf

# 4. Force re-detection
sudo rm /tmp/mihomo-interfaces.conf
sudo bash scripts/hotspot.sh start

# 5. Create udev rule for consistent naming (advanced)
sudo nano /etc/udev/rules.d/70-persistent-net.rules
# Add (replace MAC with your USB adapter MAC):
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="36:5a:03:84:9d:07", NAME="usb-tether"
sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

## 🔧 Diagnostic Commands

### Full System Check
```bash
# Run all checks at once
echo "=== Interface Status ==="
ip link show

echo "=== IP Configuration ==="
ip addr show

echo "=== WiFi Status ==="
iw dev wlp2s0 info

echo "=== Power Management ==="
iw dev wlp2s0 get power_save
iwconfig wlp2s0 | grep "Power Management"

echo "=== hostapd Status ==="
sudo systemctl status hostapd

echo "=== dnsmasq Status ==="
sudo systemctl status dnsmasq

echo "=== Connected Clients ==="
sudo hostapd_cli all_sta

echo "=== DHCP Leases ==="
cat /var/lib/misc/dnsmasq.leases

echo "=== NAT Rules ==="
sudo iptables -t nat -L POSTROUTING -v -n

echo "=== Recent Logs ==="
sudo journalctl -u hostapd -n 20
sudo journalctl -u dnsmasq -n 20
```

### Live Monitoring
```bash
# Watch logs in real-time
sudo journalctl -u hostapd -u dnsmasq -f

# Watch stability monitor
sudo journalctl -u hotspot-stability-monitor -f

# Watch connected clients
watch -n 5 'sudo hostapd_cli all_sta'

# Watch network traffic
sudo iftop -i wlp2s0

# Watch DHCP requests
sudo tcpdump -i wlp2s0 port 67 or port 68 -v
```

---

## 📊 Performance Testing

### From Client Device (Phone/Laptop)

```bash
# 1. Ping gateway
ping 192.168.1.1

# 2. Ping internet
ping 8.8.8.8

# 3. DNS test
nslookup google.com

# 4. Speedtest (install speedtest-cli)
speedtest-cli

# 5. Continuous ping monitor
ping -i 0.5 192.168.1.1 | ts '[%Y-%m-%d %H:%M:%S]'
# Should NOT see packet loss
```

### From Gateway (Debian)

```bash
# 1. Check WiFi signal quality
sudo iw dev wlp2s0 station dump | grep signal

# 2. Check channel utilization
sudo iw dev wlp2s0 survey dump | grep -A 5 "in use"

# 3. Monitor bandwidth
sudo iftop -i enx365a03849d07  # Internet interface
sudo iftop -i wlp2s0           # WiFi interface

# 4. Check packet loss
sudo tcpdump -i wlp2s0 -c 100
```

---

## 🆘 Emergency Recovery

### Complete Reset
```bash
# 1. Stop everything
sudo systemctl stop hotspot-stability-monitor
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# 2. Clean interfaces
sudo ip addr flush dev wlp2s0
sudo ip link set wlp2s0 down
sleep 2
sudo ip link set wlp2s0 up

# 3. Remove old configs
sudo rm /etc/hostapd/hostapd.conf
sudo rm /etc/dnsmasq.conf
sudo rm /var/lib/misc/dnsmasq.leases

# 4. Re-setup from scratch
cd /opt/mihomo-gateway
sudo git pull
sudo bash scripts/hotspot.sh setup
sudo bash scripts/hotspot.sh start

# 5. Re-enable monitor
sudo systemctl start hotspot-stability-monitor
```

### Factory Reset (Nuclear Option)
```bash
# WARNING: This removes ALL mihomo gateway configs!
cd /opt/mihomo-gateway
sudo bash scripts/hotspot.sh stop
sudo systemctl disable hotspot-stability-monitor
sudo systemctl stop mihomo
sudo apt purge hostapd dnsmasq -y
sudo apt install hostapd dnsmasq -y
sudo bash scripts/hotspot.sh setup
sudo bash scripts/hotspot.sh start
```

---

## 📝 Config Optimization Tips

### For Gaming (Low Latency)
```bash
# Edit hostapd.conf
sudo nano /etc/hostapd/hostapd.conf

# Optimize for gaming:
wmm_enabled=1              # Enable QoS
beacon_int=50              # Faster beacons (default 100)
dtim_period=1              # Faster sleep cycles (default 2)
max_num_sta=5              # Limit clients for better performance
ap_max_inactivity=600      # Longer timeout (10 minutes)
```

### For Stability (Many Clients)
```bash
# Edit hostapd.conf
sudo nano /etc/hostapd/hostapd.conf

# Optimize for stability:
wmm_enabled=0              # Disable QoS (more stable)
beacon_int=100             # Standard beacons
dtim_period=2              # Standard sleep
max_num_sta=20             # Allow more clients
ap_max_inactivity=300      # Standard timeout (5 minutes)
rts_threshold=2347         # Enable RTS/CTS for reliability
```

### For Power Saving (Battery)
```bash
# Not recommended for hotspot!
# But if you need it:
sudo nano /etc/hostapd/hostapd.conf

# Minimal power:
beacon_int=200             # Slower beacons
dtim_period=3              # Longer sleep
max_num_sta=5              # Fewer clients
```

---

## 🎯 Quick Fixes Checklist

- [ ] Power management disabled: `iw dev wlp2s0 get power_save` → "off"
- [ ] Interface UP: `ip link show wlp2s0` → "state UP"
- [ ] hostapd running: `systemctl is-active hostapd` → "active"
- [ ] dnsmasq running: `systemctl is-active dnsmasq` → "active"
- [ ] NAT configured: `iptables -t nat -L POSTROUTING | grep MASQUERADE`
- [ ] Channel clear: `iw dev wlp2s0 survey dump` → low noise
- [ ] Stability monitor: `systemctl is-active hotspot-stability-monitor` → "active"
- [ ] Clients can ping gateway: `ping 192.168.1.1` → OK
- [ ] Clients can ping internet: `ping 8.8.8.8` → OK
- [ ] DNS resolving: `nslookup google.com` → IP returned

**If all checked but still issues:** Check logs and run full diagnostic!
