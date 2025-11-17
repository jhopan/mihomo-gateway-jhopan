# 🚀 Mihomo Gateway v2.1.0

<div align="center">

![Mihomo Gateway](https://img.shields.io/badge/Mihomo-Gateway-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-2.1.0-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**Transparent Proxy Gateway dengan Mihomo (Clash Meta)**  
_Support Multiple Methods • Easy Setup • Production Ready_

[📖 Docs](#-dokumentasi) • [🚀 Quick Start](#-quick-start) • [⚙️ Features](#️-fitur-utama) • [💡 Dashboard](#-dashboard)

</div>

---

## 📋 Deskripsi

**Mihomo Gateway** adalah solusi transparent proxy untuk membuat hotspot WiFi dengan automatic routing ke proxy server. Cocok untuk:

- 📱 Hotspot WiFi dengan proxy otomatis
- 🏠 Home gateway untuk semua device
- 🖥️ Network-wide proxy (router mode)
- 🔐 Privacy & security untuk seluruh jaringan
- 🌏 Bypass regional restrictions

## ✨ Fitur Utama

### 🔧 Standard Naming Convention

- ✅ `proxy-providers` (organized proxy management)
- ✅ `rule-providers` (modular routing rules)
- 📁 Separate folders untuk providers

### 🚀 Multiple Proxy Methods

- **REDIRECT** - Default method (recommended, stable!)
- **TUN** - Available (disabled by default)
- ~~TPROXY~~ - Removed (unstable)

### 🌐 Network Configuration

- 🎯 Gateway IP: **192.168.1.1** (easy to remember!)
- 📱 Hotspot: 192.168.1.0/24
- 🔧 DHCP: 192.168.1.10-100
- 🌐 DNS: Port 1053 dengan fake-ip

### 🛡️ Security & Stability

- ✅ Docker/CasaOS/SSH/Tailscale bisa lewat proxy (tested safe!)
- 🚫 IPv6 disabled (stability)
- 📊 Smart routing dengan rule-providers
- 🔒 Protected Mihomo API port

### 📊 Dashboard Support

- 📁 Dedicated dashboard folder
- 🔄 Easy dashboard switching
- 💡 Multiple dashboard options (Yacd-meta, Metacubexd, etc.)
- 📥 Download directly from GitHub

### 🆕 New Features (v2.1.1)

- 📡 **Hotspot Always-On** - Watchdog auto-restart hotspot
- 👥 **Client Monitoring** - See connected devices in real-time
- 📌 **Static IP Assignment** - Set fixed IP for your devices
- 🚀 **Speed Test** - Integrated speedtest-cli in dashboard
- 🎮 **Game Optimized** - Config untuk MLBB, FF, Funny Fighter

## 🖥️ System Requirements

- **OS**: Debian 11/12, Ubuntu 20.04+, Raspberry Pi OS
- **RAM**: Minimum 512MB (1GB recommended)
- **Storage**: 100MB+ free space
- **Network**: WiFi adapter with AP mode support
- **Mihomo**: v1.18.0 or later

## 🚀 Quick Start

### 1️⃣ Install Mihomo

```bash
# Download Mihomo (compatible version)
sudo wget https://github.com/MetaCubeX/mihomo/releases/download/v1.19.16/mihomo-linux-amd64-compatible-v1.19.16.gz -O /tmp/mihomo.gz
sudo gunzip /tmp/mihomo.gz
sudo mv /tmp/mihomo /usr/local/bin/mihomo
sudo chmod +x /usr/local/bin/mihomo

# Verify installation
mihomo -v
```

### 2️⃣ Clone Repository

```bash
cd /opt
git clone https://github.com/jhopan/mihomo-gateway-jhopan.git mihomo-gateway
cd mihomo-gateway
```

### 3️⃣ Setup Configuration

```bash
# Copy config files
sudo mkdir -p /etc/mihomo
sudo cp -r config/* /etc/mihomo/

# Edit config (add your proxy servers)
sudo nano /etc/mihomo/config.yaml
sudo nano /etc/mihomo/proxy_providers/custom.yaml
```

### 4️⃣ Setup Mihomo Service

```bash
# Create log directory
sudo mkdir -p /var/log/mihomo

# Copy service file
sudo cp scripts/mihomo.service /etc/systemd/system/

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable mihomo
sudo systemctl start mihomo

# Check status
sudo systemctl status mihomo
```

### 5️⃣ Setup Routing & Hotspot

```bash
# Setup iptables (REDIRECT method)
sudo bash scripts/routing-enhanced.sh redirect

# Setup hotspot
sudo bash scripts/hotspot.sh setup

# Start hotspot
sudo bash scripts/hotspot.sh start

# Check hotspot status
sudo bash scripts/hotspot.sh status
```

### 6️⃣ Access Web UI

```
http://192.168.1.1:9090
```

**Default credentials:**

- Secret: `mihomo-gateway-2024` (ganti di config.yaml!)

### 7️⃣ Setup Additional Features (Optional)

```bash
# Install speedtest-cli
sudo apt install speedtest-cli -y

# Setup hotspot watchdog (always-on)
sudo cp scripts/hotspot-watchdog.service /etc/systemd/system/
sudo chmod +x scripts/hotspot-watchdog.sh
sudo systemctl daemon-reload
sudo systemctl enable hotspot-watchdog
sudo systemctl start hotspot-watchdog

# Setup client monitoring & speedtest
sudo chmod +x scripts/client-monitor.sh
sudo chmod +x scripts/speedtest-api.sh

# Add static IP for your phone (example)
# First, connect phone and get MAC address:
sudo bash scripts/client-monitor.sh list
# Then add static IP:
# sudo bash scripts/client-monitor.sh add-static YOUR_MAC_ADDRESS 192.168.1.100 MyPhone
```

**📖 Detailed guide:** See [docs/SETUP_NEW_FEATURES.md](docs/SETUP_NEW_FEATURES.md)

## 📊 Dashboard

Dashboard belum include di repo, download terpisah:

### Download Yacd-meta (Recommended)

```bash
cd /var/www/html/mihomo-ui/dashboard
wget https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip
unzip gh-pages.zip
mv Yacd-meta-gh-pages/* .
rm -rf Yacd-meta-gh-pages gh-pages.zip
```

Akses dashboard:

```
http://192.168.1.1/mihomo-ui/dashboard
```

### Dashboard Options

- [Yacd-meta](https://github.com/MetaCubeX/Yacd-meta) - Simple & Fast ⭐
- [Metacubexd](https://github.com/MetaCubeX/metacubexd) - Modern UI
- [Razord](https://github.com/Metacubex/Razord) - Minimal
- [Zashboard](https://github.com/Zephyruso/zashboard) - Alternative

Lihat `webui/dashboard/README.md` untuk detail.

## 📁 Project Structure

```
mihomo-gateway/
├── config/
│   ├── config.yaml              # Main configuration
│   ├── proxy_providers/         # Proxy server providers
│   │   ├── custom.yaml
│   │   ├── subscription.yaml
│   │   └── backup.yaml
│   └── rule_providers/          # Routing rule providers
│       ├── custom.yaml
│       ├── streaming.yaml
│       ├── gaming.yaml
│       └── social.yaml
│
├── scripts/
│   ├── routing-enhanced.sh      # iptables setup
│   ├── hotspot.sh              # Hotspot management
│   └── install.sh              # One-click installer
│
├── webui/
│   ├── dashboard/              # Dashboard files (download separately)
│   ├── index.php               # Web interface
│   └── assets/                 # CSS/JS
│
├── docs/
│   ├── QUICK_START.md          # Quick start guide
│   ├── INSTALL_GUIDE.md        # Detailed installation
│   ├── UPGRADE_V2.1.md         # Upgrade from v2.0
│   └── CHANGELOG_V2.1.md       # What's new
│
└── README.md                   # This file
```

cd scripts
sudo bash setup.sh

````

Script akan otomatis:

- Download Mihomo binary
- Setup direktori konfigurasi
- Install dependencies (hostapd, dnsmasq, iptables, iw, curl, jq)
- Setup systemd service
- Install Web UI
- Configure permissions

### Step 3: Start dengan Smart Setup

```bash
sudo bash smart-setup.sh
````

**SELESAI!** Smart setup akan handle semuanya!

---

## 📱 Koneksi USB Tethering

### Android:

1. Colokkan HP ke laptop via USB
2. Settings > Network > USB Tethering > Enable
3. Jalankan `sudo bash smart-setup.sh`
4. Script otomatis detect!

### iPhone:

1. Colokkan iPhone ke laptop via USB
2. Settings > Personal Hotspot > Enable
3. Jalankan `sudo bash smart-setup.sh`
4. Script otomatis detect!

**Tidak perlu tau nama interface!** Script auto-detect `usb0`, `rndis0`, dll.

## 🌐 Akses Web UI

Setelah instalasi selesai:

```
http://ip-server-anda/mihomo-ui
atau
http://localhost/mihomo-ui
```

**Default credentials:**

- Username: admin
- Password: admin123 (silakan ganti setelah login pertama)

## 🎛️ Konfigurasi

### Via Web UI (Recommended!)

**Web UI URL:**

```
http://192.168.100.1/mihomo-ui  (dari hotspot)
http://IP-SERVER/mihomo-ui       (dari network lain)
```

**Login:**

- Username: `admin`
- Password: `admin123`

### ⚙️ Hotspot Settings via Web UI

1. Login Web UI
2. Klik menu **Hotspot**
3. **Hotspot Configuration**:
   - SSID: Nama WiFi
   - Password: Min 8 karakter
   - Channel: Auto (recommended) atau manual (1-13)
4. Klik **Save Configuration**
5. Restart hotspot jika perlu

### 🌐 External Dashboard

**Akses via Web UI:**

1. Klik menu **External Dashboard**
2. Pilih: **Yacd** atau **MetaCubeX**
3. Dashboard langsung muncul di iframe!

**Atau buka langsung:**

```
https://yacd.haishan.me/?hostname=IP-SERVER&port=9090
https://metacubex.github.io/yacd/?hostname=IP-SERVER&port=9090
```

### 📝 Manual Config (Advanced)

**Mihomo Config** (`/etc/mihomo/config.yaml`):

- Port proxy (HTTP, SOCKS5, Mixed)
- External Controller API
- Rules dan rule-providers
- Proxy-providers
- DNS configuration

**Proxy Providers** (`/etc/mihomo/proxies/`):

```yaml
proxies:
  - name: "Server 1"
    type: vmess
    server: server.example.com
    port: 443
    uuid: your-uuid
```

**Rule Providers** (`/etc/mihomo/rules/`):

```yaml
payload:
  - DOMAIN-SUFFIX,youtube.com
  - DOMAIN-SUFFIX,netflix.com
```

## 🎮 Web UI Features

### 📊 Dashboard

- Status system real-time
- Traffic monitoring
- Quick actions (start/stop/restart)
- Active connections

### 🔧 Proxy Management

- Tambah/edit/hapus proxy
- Test connection
- Import proxy providers
- Switch mode (Rule/Global/Direct)

### 📡 Hotspot Control (NEW!)

- **Start/stop hotspot**
- **Configure SSID & password via UI**
- **Smart WiFi channel selection**
- **Monitor connected clients**
- **Bandwidth limit**

### 🌐 External Dashboard (NEW!)

- **Yacd Dashboard** - Simple & clean
- **MetaCubeX Dashboard** - Advanced features
- **Integrated iframe** - Akses langsung dari Web UI
- **Full API control** - Manage proxy & rules

### 📈 Data Usage

- Real-time bandwidth monitoring
- Statistics (daily/weekly/monthly)
- Per-connection breakdown
- Export to CSV

### ⚙️ Settings

- Change credentials
- Configure ports
- Backup/restore config

## 📊 Monitoring

### Real-time Monitor Script

```bash
sudo bash scripts/monitor.sh
```

Menampilkan:

- Traffic speed (upload/download)
- Active connections
- System resources (CPU, RAM, Disk)
- Hotspot clients

### Check Status

```bash
# Mihomo service
sudo systemctl status mihomo

# Hotspot
sudo systemctl status hostapd

# View logs
sudo journalctl -u mihomo -f
```

### Test Proxy

```bash
# Direct test
curl -x http://127.0.0.1:7890 https://www.google.com

# Check IP
curl -x http://127.0.0.1:7890 https://api.ipify.org
```

### Monitor via API

```bash
# Traffic
curl http://127.0.0.1:9090/traffic

# Connections
curl http://127.0.0.1:9090/connections

# Proxies
curl http://127.0.0.1:9090/proxies
```

## 🔧 Troubleshooting

### 1. Interface Tidak Terdeteksi

```bash
# Manual check
ip addr show

# Force detection
sudo bash scripts/detect-interfaces.sh detect

# Check result
cat /tmp/mihomo-interfaces.conf
```

### 2. Hotspot Tidak Start

```bash
# Check WiFi capability
iw list | grep "Supported interface modes" -A 8

# Check channel availability
sudo bash scripts/smart-channel.sh wlan0 info

# Manual start
sudo systemctl start hostapd
sudo journalctl -u hostapd -n 50
```

### 3. Mihomo Tidak Connect

```bash
# Check logs
sudo journalctl -u mihomo -n 50

# Test config
sudo /opt/mihomo/mihomo -t -d /etc/mihomo -f /etc/mihomo/config.yaml

# Restart
sudo systemctl restart mihomo
```

### 4. Client Tidak Bisa Internet

```bash
# Check IP forwarding
sysctl net.ipv4.ip_forward

# Check iptables
sudo iptables -t nat -L -n -v

# Re-apply routing
sudo bash scripts/routing.sh setup
```

### 5. USB Tethering Tidak Terdeteksi

```bash
# Check USB interfaces
ip addr show | grep -E "usb|rndis|ncm"

# Check internet
ping -c 3 8.8.8.8

# Manual detect
sudo bash scripts/detect-interfaces.sh detect
```

**Lihat troubleshooting lengkap di [QUICK_START.md](QUICK_START.md)**

## 🔄 Common Tasks

### Restart Semua

```bash
sudo systemctl restart mihomo
sudo bash scripts/hotspot.sh restart
```

### Reload Config (tanpa restart)

```bash
sudo systemctl reload mihomo
```

### Change Hotspot SSID/Password via Web UI

1. Web UI > Hotspot > Hotspot Configuration
2. Edit SSID/Password/Channel
3. Save Configuration

### Change Hotspot via Command

```bash
sudo bash scripts/hotspot.sh change-ssid "NewName"
sudo bash scripts/hotspot.sh change-password "newpass123"
sudo bash scripts/hotspot.sh restart
```

### Check Hotspot Clients

```bash
sudo bash scripts/hotspot.sh clients
```

### Re-detect Interfaces

```bash
sudo bash scripts/detect-interfaces.sh detect
```

---

## 📚 Documentation

### 🚀 Getting Started

- **[ULTRA_QUICK.md](ULTRA_QUICK.md)** - ⚡ Setup dalam 3 langkah! (TERCEPAT!)
- **[QUICK_START.md](QUICK_START.md)** - 📖 Panduan lengkap step-by-step
- **[INSTALL_GUIDE.md](INSTALL_GUIDE.md)** - 📦 Instalasi detail manual

### 📖 Reference

- **[COMMANDS.md](COMMANDS.md)** - 💻 Referensi command lengkap
- **[COMPARISON.md](COMPARISON.md)** - 📊 Perbandingan dengan OpenClash

### 📝 Development

- **[CHANGELOG.md](CHANGELOG.md)** - 🔄 Version history & updates
- **[TODO.md](TODO.md)** - 📋 Roadmap & future plans
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 📊 Project overview & status

---

## 🎯 Key Features Summary

| Feature                   | Status | Notes                      |
| ------------------------- | ------ | -------------------------- |
| USB Tethering Auto-Detect | ✅     | Support Android/iPhone     |
| Smart Interface Detection | ✅     | Priority: USB > Eth > WiFi |
| Smart WiFi Channel        | ✅     | Auto-scan & select best    |
| Web UI Hotspot Config     | ✅     | SSID, password, channel    |
| External Dashboard        | ✅     | Yacd & MetaCubeX           |
| One-Command Setup         | ✅     | `smart-setup.sh`           |
| Transparent Proxy         | ✅     | Auto for all clients       |
| Real-time Monitoring      | ✅     | Traffic, connections, etc  |

---

## 🔐 Security

1. **Ganti password default** di Web UI (`admin/admin123`)
2. **Firewall** - batasi akses external controller jika perlu
3. **Regular updates** - update Mihomo berkala

---

## 📞 Quick Reference

| Task                 | Command                                  |
| -------------------- | ---------------------------------------- |
| **Start All**        | `sudo bash scripts/smart-setup.sh`       |
| **Check Status**     | `systemctl status mihomo`                |
| **Monitor**          | `bash scripts/monitor.sh`                |
| **Restart Hotspot**  | `sudo bash scripts/hotspot.sh restart`   |
| **Detect Interface** | `sudo bash scripts/detect-interfaces.sh` |
| **Re-apply Routes**  | `sudo bash scripts/routing.sh setup`     |

---

## 📚 Resources

- [Mihomo Documentation](https://wiki.metacubex.one/)
- [Clash Meta GitHub](https://github.com/MetaCubeX/mihomo)
- [OpenClash](https://github.com/vernesong/OpenClash)

## 🤝 Contributing

Feel free to contribute dengan:

- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## 📄 License

MIT License - Free to use and modify

## ⚠️ Disclaimer

Tool ini untuk educational purposes. Pastikan penggunaan proxy sesuai dengan hukum dan regulasi di negara Anda.
