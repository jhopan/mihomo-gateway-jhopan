# Mihomo Gateway dengan Hotspot WiFi

Gateway internet berbasis Mihomo (Clash Meta) dengan WiFi hotspot terintegrasi. Laptop menjadi gateway yang membagikan internet via hotspot WiFi dengan routing melalui proxy Mihomo.

## 🎯 Fitur Utama

- **Mihomo Gateway**: Proxy traffic melalui Mihomo (Clash Meta)
- **WiFi Hotspot**: Access Point menggunakan hostapd
- **USB Tethering**: Internet dari HP via USB
- **Auto Routing**: Game, streaming, sosmed dengan rule-based routing
- **WebUI Dashboard**: Monitoring dan control via web interface
- **CasaOS Integration**: Container management dengan CasaOS
- **USB Watchdog**: Auto-fix USB tethering yang hang/timeout

## 📋 Spesifikasi Sistem

- **OS**: Debian Trixie (testing)
- **Gateway IP**: 192.168.2.1
- **DHCP Range**: 192.168.2.10 - 192.168.2.100
- **WiFi SSID**: Mihomo-Gateway
- **WiFi Password**: mihomo2024
- **WiFi Channel**: 6 (HT40 disabled untuk stabilitas)

## 🚀 Quick Start

### Install dari GitHub

```bash
# Clone repository
git clone https://github.com/jhopan/mihomo-gateway-jhopan.git
cd mihomo-gateway-jhopan

# Install
sudo bash install.sh
```

### Install Manual

```bash
# 1. Install dependencies
sudo apt update
sudo apt install hostapd dnsmasq iptables nginx php-fpm git

# 2. Clone dan setup
git clone https://github.com/jhopan/mihomo-gateway-jhopan.git /opt/mihomo-gateway
cd /opt/mihomo-gateway

# 3. Setup hotspot
sudo bash scripts/hotspot.sh start

# 4. Setup USB watchdog (auto-fix USB issues)
sudo bash setup-usb-watchdog.sh

# 5. Setup WebUI sudo permissions
sudo bash setup-webui-sudo.sh

# 6. Deploy WebUI
sudo cp webui/api-dashboard.php /var/www/html/
```

## 🌐 Akses Services

- **WebUI Dashboard**: http://192.168.2.1:8080
- **CasaOS**: http://192.168.2.1
- **Mihomo API**: http://127.0.0.1:9090 (secret: mihomo-gateway-2024)
- **SSH**: ssh jhopan@192.168.2.1

## 📁 Struktur Project

```
mihomo-gateway/
├── config/
│   ├── config.yaml              # Mihomo config
│   ├── proxy_providers/         # VPN providers
│   └── rule_providers/          # Routing rules
├── scripts/
│   ├── hotspot.sh              # Hotspot control
│   └── usb-watchdog.sh         # USB monitoring
├── systemd/
│   └── usb-watchdog.service    # Watchdog service
├── webui/
│   └── api-dashboard.php       # Dashboard API
├── install.sh                   # Main installer
├── setup-usb-watchdog.sh       # Setup USB watchdog
├── setup-webui-sudo.sh         # Setup WebUI permissions
├── fix-nat-now.sh              # Quick NAT fix
├── emergency-fix-network.sh    # Emergency network reset
├── quick-fix-hotspot.sh        # Quick hotspot fix
├── fix-casaos.sh               # Fix CasaOS issues
└── reinstall-casaos.sh         # Reinstall CasaOS
```

## 🔧 Maintenance Scripts

### Hotspot Management
```bash
# Start hotspot
sudo bash scripts/hotspot.sh start

# Stop hotspot
sudo bash scripts/hotspot.sh stop

# Restart hotspot
sudo bash scripts/hotspot.sh restart

# Check status
sudo bash scripts/hotspot.sh status
```

### Network Troubleshooting
```bash
# Quick NAT fix (USB interface changed)
sudo bash fix-nat-now.sh

# Emergency network fix (USB timeout/hang)
sudo bash emergency-fix-network.sh

# Quick hotspot fix (conflicts)
sudo bash quick-fix-hotspot.sh
```

### USB Watchdog
```bash
# View watchdog status
sudo systemctl status usb-watchdog

# View watchdog logs
sudo journalctl -u usb-watchdog -f
sudo tail -f /var/log/usb-watchdog.log

# Restart watchdog
sudo systemctl restart usb-watchdog
```

### CasaOS Management
```bash
# Fix CasaOS issues
sudo bash fix-casaos.sh

# Reinstall CasaOS (last resort)
sudo bash reinstall-casaos.sh
```

## ⚙️ Konfigurasi

### Mihomo Config (`config/config.yaml`)

```yaml
port: 7891
socks-port: 7892
mixed-port: 7893
external-controller: 0.0.0.0:9090
secret: "mihomo-gateway-2024"

proxy-providers:
  VPN-1:
    type: file
    path: ./proxy_providers/vpn1.yaml
  VPN-2:
    type: file
    path: ./proxy_providers/vpn2.yaml

proxy-groups:
  - name: INTERNET-UMUM
    type: fallback
    proxies: [VPN-1, VPN-2]
  
  - name: STREAMING×SOSMED
    type: select
    proxies: [VPN-1, VPN-2]
  
  - name: GAME
    type: url-test
    proxies: [VPN-1, VPN-2]

rules:
  - DST-PORT,8080-8099,GAME        # MLBB
  - DST-PORT,10000-10050,GAME      # Free Fire
  - DOMAIN-SUFFIX,netflix.com,STREAMING×SOSMED
  - DOMAIN-SUFFIX,youtube.com,STREAMING×SOSMED
  - MATCH,INTERNET-UMUM
```

### Hotspot Config

Edit `scripts/hotspot.sh`:
```bash
SSID="Mihomo-Gateway"
PASSWORD="mihomo2024"
CHANNEL="6"
IP_ADDRESS="192.168.2.1"
DHCP_RANGE_START="192.168.2.10"
DHCP_RANGE_END="192.168.2.100"
```

## 🐛 Troubleshooting

### Problem: Internet dari hotspot tidak jalan
**Solusi:**
```bash
# Cek USB interface
ip addr show

# Fix NAT routing
sudo bash fix-nat-now.sh

# Atau emergency fix
sudo bash emergency-fix-network.sh
```

### Problem: Hotspot tidak start (NetworkManager conflict)
**Solusi:**
```bash
# Quick fix
sudo bash quick-fix-hotspot.sh

# Atau restart dengan conflict cleanup
sudo systemctl stop NetworkManager wpa_supplicant
sudo bash scripts/hotspot.sh restart
```

### Problem: CasaOS gagal load apps
**Solusi:**
```bash
# Update Docker (butuh API 1.44+)
sudo apt update
sudo apt install --only-upgrade docker-ce docker-ce-cli

# Add user ke docker group
sudo usermod -aG docker jhopan
newgrp docker

# Restart CasaOS
sudo systemctl restart casaos-gateway casaos-message-bus casaos-app-management casaos
```

### Problem: USB tethering timeout (NETDEV WATCHDOG error)
**Solusi:**
USB Watchdog akan otomatis fix ini setiap 30 detik. Kalau masih error:
```bash
# Manual fix
sudo bash emergency-fix-network.sh

# Atau cabut-colok USB cable
# Tunggu 10 detik
# Colok lagi, lalu:
sudo bash fix-nat-now.sh
```

## 📊 Monitoring

### Check All Services
```bash
# Mihomo
sudo systemctl status mihomo

# Hotspot
sudo systemctl status hostapd dnsmasq

# USB Watchdog
sudo systemctl status usb-watchdog

# CasaOS
sudo systemctl status casaos casaos-gateway
```

### View Logs
```bash
# Mihomo logs
sudo journalctl -u mihomo -f

# Hotspot logs
sudo journalctl -u hostapd -f
sudo journalctl -u dnsmasq -f

# USB Watchdog logs
sudo tail -f /var/log/usb-watchdog.log

# CasaOS logs
sudo journalctl -u casaos -f
```

### Check Network Status
```bash
# Check interfaces
ip addr show

# Check routing
ip route

# Check NAT rules
sudo iptables -t nat -L -v -n

# Check DHCP clients
sudo cat /var/lib/misc/dnsmasq.leases

# Check hotspot clients
sudo hostapd_cli all_sta
```

## 🔄 Updates

### Update Repository
```bash
cd /opt/mihomo-gateway
git pull
```

### Update Mihomo Binary
```bash
# Download latest release
wget https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-v*.gz
gunzip mihomo-linux-amd64-v*.gz
sudo mv mihomo-linux-amd64-v* /usr/local/bin/mihomo
sudo chmod +x /usr/local/bin/mihomo
sudo systemctl restart mihomo
```

## 🤝 Contributing

Feel free to submit issues dan pull requests!

## 📝 License

MIT License

## 👤 Author

jhopan - [GitHub](https://github.com/jhopan)

## 🙏 Credits

- [Mihomo (Clash Meta)](https://github.com/MetaCubeX/mihomo)
- [CasaOS](https://github.com/IceWhaleTech/CasaOS)
- [hostapd](https://w1.fi/hostapd/)
- [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)
