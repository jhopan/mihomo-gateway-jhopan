# 🎮 Setup Guide - Game Optimized Config

## 📋 Yang Sudah Diperbaiki

### 1. ✅ Mihomo Service Path

- Fixed: `/usr/local/bin/mihomo` (bukan `/opt/mihomo/mihomo`)
- Service file sudah benar

### 2. ✅ Hotspot Channel

- Default channel: **11** (bukan 6 lagi!)
- Priority: 1, 6, 11, 3, 9, 13...
- Smart fallback jika scan gagal

### 3. ✅ Config Optimized untuk Game

- File: `config-game-optimized.yaml`
- TUN mode: **ENABLED**
- Game rules untuk MLBB, FF, Funny Fighter
- Separate proxy groups untuk Game, Streaming, Sosmed

### 4. ✅ Hotspot Start Fixed

- IP addr command diperbaiki
- Added delays untuk stabilitas
- Better error handling

## 🚀 Cara Install / Update

### Step 1: Backup Config Lama

```bash
cd /opt/mihomo-gateway
sudo cp /etc/mihomo/config.yaml /etc/mihomo/config.yaml.backup
```

### Step 2: Pull Update dari GitHub

```bash
cd /opt/mihomo-gateway
git pull
```

### Step 3: Copy Config Baru (Game Optimized)

```bash
# Gunakan config yang sudah dioptimasi untuk game
sudo cp config/config-game-optimized.yaml /etc/mihomo/config.yaml

# Setup proxy providers
sudo cp config/proxy_providers/vpn1.yaml /etc/mihomo/proxy_providers/
sudo cp config/proxy_providers/vpn2.yaml /etc/mihomo/proxy_providers/
```

### Step 4: Edit Config - Tambah Server Proxy Kamu

```bash
# Edit VPN-1 (server Indonesia untuk game)
sudo nano /etc/mihomo/proxy_providers/vpn1.yaml

# Edit VPN-2 (server global untuk streaming)
sudo nano /etc/mihomo/proxy_providers/vpn2.yaml

# Verify config syntax
mihomo -t -f /etc/mihomo/config.yaml
```

### Step 5: Update Mihomo Service

```bash
# Copy service file terbaru
sudo cp scripts/mihomo.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Restart Mihomo
sudo systemctl restart mihomo

# Check status
sudo systemctl status mihomo
```

### Step 6: Update & Restart Hotspot

```bash
# Update hotspot script (dengan channel 11)
sudo bash scripts/hotspot.sh setup

# Restart hotspot
sudo bash scripts/hotspot.sh stop
sudo bash scripts/hotspot.sh start

# Check status
sudo bash scripts/hotspot.sh status
```

### Step 7: Setup Routing (TUN Mode)

```bash
# Karena TUN enabled, routing otomatis
# Tapi tetap setup iptables untuk backup
sudo bash scripts/routing-enhanced.sh redirect
```

## 🎯 Verifikasi Setup

### Check Mihomo

```bash
# Status service
sudo systemctl status mihomo

# View logs
sudo journalctl -u mihomo -f

# Test mihomo binary
mihomo -v
```

### Check Hotspot

```bash
# Status
sudo bash scripts/hotspot.sh status

# View logs
sudo journalctl -u hostapd -f
sudo journalctl -u dnsmasq -f
```

### Check Channel

```bash
# Lihat channel yang dipilih
sudo iw dev wlan0 info | grep channel

# Scan nearby networks
sudo bash scripts/smart-channel.sh wlan0 scan

# Test channel 11
sudo bash scripts/smart-channel.sh wlan0 test 11
```

## 🎮 Config Explanation

### TUN Mode

```yaml
tun:
  enable: true # ✅ Enabled untuk better performance
  device: utun
  mtu: 1500 # Optimal untuk ISP Indonesia
  stack: system
  auto-route: true # Routing otomatis
```

**Kenapa TUN?**

- Lebih efficient daripada REDIRECT
- Routing otomatis, gak perlu iptables kompleks
- Better untuk gaming (lower latency)
- UDP support built-in

### Proxy Groups

#### GAME (url-test)

```yaml
- name: GAME
  type: url-test # Auto-select fastest
  use:
    - VPN-1 # Server Indonesia only
  interval: 30 # Test every 30s
```

**Kenapa url-test?**

- Auto-pilih server tercepat
- Real-time latency monitoring
- Auto-switch kalau server down

#### STREAMING×SOSMED (select)

```yaml
- name: STREAMING×SOSMED
  type: select # Manual selection
  use:
    - VPN-2 # Server global
    - VPN-1
```

**Kenapa select?**

- Bisa pilih server spesifik
- Bebas ganti-ganti
- Cocok untuk bypass geo-restriction

### Game Rules

**Port-based (UDP)**

```yaml
- DST-PORT,5000-5221,GAME,udp,no-resolve # MLBB
- DST-PORT,5055-5058,GAME,udp,no-resolve # FF
```

**IP-based (Server MLBB/FF)**

```yaml
- IP-CIDR,103.10.124.0/23,GAME,no-resolve # Moonton ID
- IP-CIDR,13.213.0.0/16,GAME,no-resolve # AWS SG
```

**Kenapa port + IP?**

- Port-based: catch all game traffic
- IP-based: ensure game server routed correctly
- Kombinasi = zero packet loss

## 🔧 Troubleshooting

### Mihomo Service Fails

```bash
# Check error
sudo journalctl -u mihomo -n 50

# Common issue: config syntax error
mihomo -t -f /etc/mihomo/config.yaml

# Check binary path
ls -la /usr/local/bin/mihomo

# If wrong path in service file:
sudo nano /etc/systemd/system/mihomo.service
# Change ExecStart to: /usr/local/bin/mihomo
sudo systemctl daemon-reload
sudo systemctl restart mihomo
```

### Hotspot Fails to Start

```bash
# Check channel
sudo iw dev wlan0 info

# Try manual channel
sudo bash scripts/hotspot.sh setup
# Edit /etc/hostapd/hostapd.conf
sudo nano /etc/hostapd/hostapd.conf
# Change: channel=11

# Restart
sudo bash scripts/hotspot.sh start
```

### Channel Auto-Selection Fails

```bash
# Test channel manually
sudo bash scripts/smart-channel.sh wlan0 test 11
sudo bash scripts/smart-channel.sh wlan0 test 6
sudo bash scripts/smart-channel.sh wlan0 test 1

# Show supported channels
sudo bash scripts/smart-channel.sh wlan0 info

# Force specific channel
sudo bash scripts/hotspot.sh setup
# Edit config: CHANNEL="11"
```

### Game Lag / High Ping

```bash
# Check proxy group
# Pastikan GAME menggunakan VPN-1 (server Indonesia)

# Test latency
curl -x http://127.0.0.1:7890 http://www.gstatic.com/generate_204 -w "%{time_total}\n"

# Check routing
sudo ip route show table 100

# Monitor traffic
sudo iftop -i utun
```

### TUN Mode Issues

```bash
# Check if TUN device exists
ip link show utun

# Check TUN in mihomo logs
sudo journalctl -u mihomo | grep -i tun

# If TUN fails, fallback to REDIRECT:
sudo nano /etc/mihomo/config.yaml
# Change: tun.enable: false
sudo systemctl restart mihomo
sudo bash scripts/routing-enhanced.sh redirect
```

## 📝 Config Customization

### Tambah Server Proxy

**VPN-1 (Game)**

```bash
sudo nano /etc/mihomo/proxy_providers/vpn1.yaml
```

Tambah:

```yaml
- name: "ID-Jakarta-1"
  type: vmess
  server: your-server.com
  port: 443
  uuid: your-uuid
  # ... config details
```

**VPN-2 (Streaming)**

```bash
sudo nano /etc/mihomo/proxy_providers/vpn2.yaml
```

### Tambah Game Rules

Edit `/etc/mihomo/config.yaml`:

```yaml
rules:
  # Tambah port game lain
  - DST-PORT,7000-7100,GAME,udp,no-resolve # Game X

  # Tambah IP server game
  - IP-CIDR,1.2.3.0/24,GAME,no-resolve # Game Y server
```

### Change Default Channel

```bash
sudo nano scripts/hotspot.sh
# Line 12: CHANNEL="11"  # Ganti ke channel lain
```

## 🎯 Tips Optimasi

### Untuk Gaming

1. Gunakan server Indonesia (VPN-1)
2. Enable TUN mode
3. Set `tcp-concurrent: true`
4. Monitor ping dengan: `ping -I utun 8.8.8.8`

### Untuk Streaming

1. Gunakan server Singapore/US (VPN-2)
2. Check bandwidth: `speedtest`
3. Monitor: `iftop -i utun`

### Untuk Stabilitas

1. Enable watchdog: `sudo systemctl enable hotspot-watchdog`
2. Monitor logs: `sudo journalctl -f`
3. Check clients: `sudo bash scripts/client-monitor.sh list`

---

**Need help?** Check logs atau open issue di GitHub! 🙏
