# 🚀 Setup Guide - New Features v2.1.1

## 📦 Installation Requirements

### 1. Install Speedtest CLI

```bash
# Install speedtest-cli
sudo apt update
sudo apt install speedtest-cli -y

# Test speedtest
speedtest
```

### 2. Setup Hotspot Watchdog (Always-On)

```bash
# Copy service file
sudo cp /opt/mihomo-gateway/scripts/hotspot-watchdog.service /etc/systemd/system/

# Make script executable
sudo chmod +x /opt/mihomo-gateway/scripts/hotspot-watchdog.sh

# Enable and start watchdog
sudo systemctl daemon-reload
sudo systemctl enable hotspot-watchdog
sudo systemctl start hotspot-watchdog

# Check status
sudo systemctl status hotspot-watchdog
```

Watchdog akan:

- 🔍 Check hotspot setiap 30 detik
- 🔄 Auto-restart jika mati
- 📝 Log ke `/var/log/hotspot-watchdog.log`

### 3. Setup Client Monitoring

```bash
# Make script executable
sudo chmod +x /opt/mihomo-gateway/scripts/client-monitor.sh

# View connected clients
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh list

# Add static IP for your phone
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh add-static aa:bb:cc:dd:ee:ff 192.168.1.100 MyPhone
```

**Cara dapat MAC address HP kamu:**

1. Connect HP ke hotspot
2. Jalankan: `sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh list`
3. Lihat MAC address HP kamu
4. Tambahkan static IP dengan command di atas

### 4. Update Mihomo Binary

```bash
# Download new binary (compatible version)
sudo wget https://github.com/MetaCubeX/mihomo/releases/download/v1.19.16/mihomo-linux-amd64-compatible-v1.19.16.gz -O /tmp/mihomo.gz
sudo gunzip /tmp/mihomo.gz
sudo mv /tmp/mihomo /usr/local/bin/mihomo
sudo chmod +x /usr/local/bin/mihomo

# Restart service
sudo systemctl restart mihomo

# Verify
mihomo -v
```

## 🎯 Using New Features

### 👥 Connected Clients Monitor

**CLI Commands:**

```bash
# List current clients
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh list

# Show client history
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh history

# Real-time monitoring (auto-refresh)
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh monitor

# List static IP leases
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh static
```

**Web Dashboard:**

- Open Web UI → Navigate to "👥 Connected Clients"
- See all connected devices with MAC, IP, hostname
- Add static IP directly from dashboard
- Monitor in real-time

### 🚀 Speed Test

**CLI Commands:**

```bash
# Run speedtest
sudo bash /opt/mihomo-gateway/scripts/speedtest-api.sh run

# Get cached result
sudo bash /opt/mihomo-gateway/scripts/speedtest-api.sh cached

# Simple output
sudo bash /opt/mihomo-gateway/scripts/speedtest-api.sh simple
```

**Web Dashboard:**

- Open Web UI → Navigate to "🚀 Speed Test"
- Click "Run Speed Test" button
- Wait for results (10-30 seconds)
- See download/upload speed, ping, server info

### 📡 Hotspot Always-On

**Manual Commands:**

```bash
# Check hotspot status
sudo bash /opt/mihomo-gateway/scripts/hotspot-watchdog.sh check

# Restart hotspot manually
sudo bash /opt/mihomo-gateway/scripts/hotspot-watchdog.sh restart

# View logs
sudo journalctl -u hotspot-watchdog -f
```

Watchdog runs automatically in background!

## 📝 Example: Setup Static IP for Phone

**Step 1: Find your phone MAC address**

```bash
# Connect phone to hotspot first
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh list
```

Output:

```
===================================
  Connected Clients (Hotspot)
===================================
MAC Address        IP Address      Hostname             Status
-----------------------------------
aa:bb:cc:dd:ee:ff  192.168.1.52    MyPhone              REACHABLE
```

**Step 2: Add static IP**

```bash
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh add-static aa:bb:cc:dd:ee:ff 192.168.1.100 MyPhone
```

**Step 3: Reconnect phone**

- Disconnect from hotspot
- Connect again
- Check IP: should be 192.168.1.100 now!

**Step 4: Verify**

```bash
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh static
```

Output:

```
===================================
  Static IP Leases
===================================
MAC Address        IP Address      Hostname
-----------------------------------
aa:bb:cc:dd:ee:ff  192.168.1.100   MyPhone
```

Done! HP kamu sekarang akan selalu dapat IP `192.168.1.100` 🎉

## 🔧 Configuration Files

### Hotspot Watchdog Config

Edit `/opt/mihomo-gateway/scripts/hotspot-watchdog.sh`:

```bash
CHECK_INTERVAL=30  # Check every 30 seconds (bisa diubah)
MAX_RETRIES=3      # Max retry attempts before giving up
LOG_FILE="/var/log/hotspot-watchdog.log"
```

### Static IP Leases

File: `/etc/dnsmasq.d/static-leases.conf`

Format:

```
dhcp-host=MAC_ADDRESS,IP_ADDRESS,HOSTNAME,infinite
```

Example:

```
dhcp-host=aa:bb:cc:dd:ee:ff,192.168.1.100,MyPhone,infinite
dhcp-host=11:22:33:44:55:66,192.168.1.101,Laptop,infinite
```

## 📊 Web Dashboard Access

After setup, access dashboard at:

```
http://192.168.1.1
```

**New menu items:**

- 👥 **Connected Clients** - See all devices, add static IP
- 🚀 **Speed Test** - Run internet speed test
- 📡 **Hotspot** - (existing) Hotspot management

## 🐛 Troubleshooting

### Watchdog not starting

```bash
# Check logs
sudo journalctl -u hotspot-watchdog -n 50

# Restart service
sudo systemctl restart hotspot-watchdog

# Check if script is executable
ls -la /opt/mihomo-gateway/scripts/hotspot-watchdog.sh
```

### Speedtest not working

```bash
# Install speedtest-cli
sudo apt install speedtest-cli -y

# Test manually
speedtest

# Check script
bash /opt/mihomo-gateway/scripts/speedtest-api.sh simple
```

### Static IP not applied

```bash
# Check dnsmasq config
sudo cat /etc/dnsmasq.d/static-leases.conf

# Restart dnsmasq
sudo systemctl restart dnsmasq

# Reconnect device to hotspot
```

### Clients not showing

```bash
# Check if wlan0 is up
ip addr show wlan0

# Check ARP table
ip neigh show dev wlan0

# Run monitor manually
sudo bash /opt/mihomo-gateway/scripts/client-monitor.sh list
```

## 📚 Additional Resources

- [Main README](../README.md) - Project overview
- [UPGRADE_V2.1.md](../UPGRADE_V2.1.md) - Upgrade guide
- [CHANGELOG_V2.1.md](../CHANGELOG_V2.1.md) - What's new

---

**Need help?** Open an issue on GitHub! 🙏
