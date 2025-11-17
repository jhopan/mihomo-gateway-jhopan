# Panduan Lengkap Instalasi dan Konfigurasi Mihomo Gateway

## 📚 Daftar Isi

1. [Persiapan System](#persiapan-system)
2. [Instalasi Mihomo](#instalasi-mihomo)
3. [Konfigurasi Proxy](#konfigurasi-proxy)
4. [Setup Routing & Transparent Proxy](#setup-routing)
5. [Setup Hotspot WiFi](#setup-hotspot)
6. [Akses Web UI](#akses-web-ui)
7. [Tips & Troubleshooting](#troubleshooting)

---

## 1. Persiapan System

### Requirement Minimum

- Debian 11/12 atau Ubuntu 20.04+
- RAM minimal 1GB (recommended 2GB+)
- Storage minimal 2GB free space
- 2 network interface (1 untuk WAN, 1 untuk LAN/WiFi)
- Akses root/sudo

### Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### Cek Network Interfaces

```bash
ip addr show
# atau
ip link show
```

**Catat nama interface Anda:**

- WAN (internet): biasanya `eth0`, `enp0s3`, `wlan0`
- LAN (local): biasanya `eth1`, `enp0s8`
- WiFi (hotspot): biasanya `wlan0`, `wlan1`

---

## 2. Instalasi Mihomo

### Opsi A: Instalasi Otomatis (Recommended)

```bash
# Clone atau copy project ini
cd /tmp
# Jika sudah ada folder project, masuk ke folder tersebut

# Jalankan script instalasi
cd mihomo-gateway/scripts
sudo bash setup.sh
```

Script akan otomatis:

- Download Mihomo binary
- Setup direktori konfigurasi
- Install web server & PHP
- Setup systemd service
- Konfigurasi permissions

### Opsi B: Instalasi Manual

#### Step 1: Download Mihomo

```bash
# Buat direktori
sudo mkdir -p /opt/mihomo
cd /opt/mihomo

# Download (ganti dengan arsitektur Anda)
# Untuk x86_64:
sudo wget https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-v1.18.0.gz

# Extract
sudo gunzip mihomo-linux-amd64-v1.18.0.gz
sudo mv mihomo-linux-amd64-v1.18.0 mihomo
sudo chmod +x mihomo

# Test
./mihomo -v
```

#### Step 2: Setup Direktori

```bash
sudo mkdir -p /etc/mihomo
sudo mkdir -p /etc/mihomo/proxies
sudo mkdir -p /etc/mihomo/rules
sudo mkdir -p /var/log/mihomo
```

#### Step 3: Copy Konfigurasi

```bash
# Copy config dari project
sudo cp config/config.yaml /etc/mihomo/
sudo cp config/proxies/* /etc/mihomo/proxies/
sudo cp config/rules/* /etc/mihomo/rules/
```

#### Step 4: Generate Secret Key

```bash
# Generate random secret untuk API
openssl rand -hex 16
# Copy hasilnya, contoh: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

# Edit config dan ganti secret
sudo nano /etc/mihomo/config.yaml
# Cari baris: secret: "your-secret-key-change-this"
# Ganti dengan secret yang di-generate tadi
```

#### Step 5: Setup Systemd Service

```bash
# Copy service file
sudo cp scripts/mihomo.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable mihomo

# Start service
sudo systemctl start mihomo

# Check status
sudo systemctl status mihomo
```

#### Step 6: Install Web Server & PHP

```bash
# Install Apache dan PHP
sudo apt install -y apache2 php php-curl php-json php-mbstring

# Enable mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo systemctl restart apache2
```

#### Step 7: Setup Web UI

```bash
# Copy web UI
sudo mkdir -p /var/www/html/mihomo-ui
sudo cp -r webui/* /var/www/html/mihomo-ui/

# Set permissions
sudo chown -R www-data:www-data /var/www/html/mihomo-ui/
sudo chmod -R 755 /var/www/html/mihomo-ui/
```

#### Step 8: Configure Sudoers

```bash
# Edit sudoers
sudo visudo

# Tambahkan di akhir file:
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/sbin/iptables, /usr/sbin/ip, /usr/bin/hostapd, /usr/sbin/dnsmasq

# Save dan exit (Ctrl+X, Y, Enter)
```

---

## 3. Konfigurasi Proxy

### Tambah Proxy Manual

Edit file `/etc/mihomo/proxies/custom.yaml`:

```bash
sudo nano /etc/mihomo/proxies/custom.yaml
```

**Contoh VMess:**

```yaml
proxies:
  - name: "My VMess Server"
    type: vmess
    server: your-server.com
    port: 443
    uuid: your-uuid-here
    alterId: 0
    cipher: auto
    tls: true
    skip-cert-verify: false
    network: ws
    ws-opts:
      path: /vmess
      headers:
        Host: your-server.com
```

**Contoh Trojan:**

```yaml
- name: "My Trojan Server"
  type: trojan
  server: your-server.com
  port: 443
  password: your-password
  sni: your-server.com
  skip-cert-verify: false
```

**Contoh Shadowsocks:**

```yaml
- name: "My SS Server"
  type: ss
  server: your-server.com
  port: 8388
  cipher: aes-256-gcm
  password: your-password
  udp: true
```

### Menggunakan Subscription URL

Edit file `/etc/mihomo/config.yaml`:

```bash
sudo nano /etc/mihomo/config.yaml
```

Cari bagian `proxy-providers` dan edit `provider1`:

```yaml
proxy-providers:
  provider1:
    type: http
    url: "https://your-subscription-url-here"
    interval: 3600
    path: /etc/mihomo/proxies/provider1.yaml
    health-check:
      enable: true
      interval: 300
      url: http://www.gstatic.com/generate_204
```

### Restart Service

```bash
sudo systemctl restart mihomo
```

### Test Proxy

```bash
# Test HTTP proxy
curl -x http://127.0.0.1:7890 https://www.google.com

# Test SOCKS5 proxy
curl -x socks5://127.0.0.1:7891 https://www.google.com

# Cek IP publik via proxy
curl -x http://127.0.0.1:7890 https://api.ipify.org
```

---

## 4. Setup Routing & Transparent Proxy

### Edit Interface Names

```bash
sudo nano scripts/routing.sh
```

Edit baris berikut sesuai dengan interface Anda:

```bash
WAN_INTERFACE="eth0"   # Ganti dengan interface internet Anda
LAN_INTERFACE="eth1"   # Ganti dengan interface LAN Anda
WIFI_INTERFACE="wlan0" # Ganti dengan interface WiFi Anda
```

### Run Script

```bash
# Full setup (NAT + Transparent Proxy + DNS)
sudo bash scripts/routing.sh setup

# Atau hanya NAT (tanpa transparent proxy)
sudo bash scripts/routing.sh nat-only

# Lihat rules yang aktif
sudo bash scripts/routing.sh show
```

### Enable IP Forwarding Permanent

```bash
# Cek current setting
sysctl net.ipv4.ip_forward

# Enable permanent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Konfigurasi Client

Setelah routing aktif, client di LAN akan otomatis menggunakan proxy.

**Untuk client yang tidak support transparent proxy:**

Set manual di browser/aplikasi:

- HTTP Proxy: `192.168.x.x:7890` (IP laptop Debian Anda)
- SOCKS5 Proxy: `192.168.x.x:7891`

---

## 5. Setup Hotspot WiFi

### Cek WiFi Interface

```bash
# Cek apakah WiFi support AP mode
iw list | grep "Supported interface modes" -A 8

# Harus ada: * AP
```

### Edit Konfigurasi Hotspot

```bash
sudo nano scripts/hotspot.sh
```

Edit bagian konfigurasi:

```bash
WIFI_INTERFACE="wlan0"        # Interface WiFi Anda
INTERNET_INTERFACE="eth0"     # Interface internet Anda
SSID="Mihomo-Gateway"         # Nama hotspot
PASSWORD="mihomo2024"         # Password (min 8 karakter)
CHANNEL="6"                   # Channel WiFi
IP_ADDRESS="192.168.100.1"    # IP hotspot
```

### Setup Hotspot

```bash
# Install dan konfigurasi
sudo bash scripts/hotspot.sh setup

# Start hotspot
sudo bash scripts/hotspot.sh start

# Check status
sudo bash scripts/hotspot.sh status

# Lihat client yang terkoneksi
sudo bash scripts/hotspot.sh clients
```

### Change SSID/Password

```bash
# Change SSID
sudo bash scripts/hotspot.sh change-ssid "NewSSIDName"

# Change password
sudo bash scripts/hotspot.sh change-password "newpassword123"

# Restart untuk apply
sudo bash scripts/hotspot.sh restart
```

### Troubleshooting Hotspot

```bash
# Check hostapd
sudo systemctl status hostapd
sudo journalctl -u hostapd -n 50

# Check dnsmasq
sudo systemctl status dnsmasq
sudo journalctl -u dnsmasq -n 50

# Check interface
ip addr show wlan0

# Manual test hostapd
sudo hostapd /etc/hostapd/hostapd.conf
```

---

## 6. Akses Web UI

### URL Akses

```
http://IP-SERVER-ANDA/mihomo-ui

Contoh:
http://192.168.1.100/mihomo-ui
http://localhost/mihomo-ui (jika akses dari laptop itu sendiri)
```

### Login Default

- **Username:** `admin`
- **Password:** `admin123`

⚠️ **PENTING:** Ganti password default setelah login pertama!

### Fitur Web UI

#### Dashboard

- Monitor traffic real-time
- Lihat status system
- Control Mihomo service (start/stop/restart)
- Quick statistics

#### Proxies

- Lihat semua proxy yang tersedia
- Test proxy latency
- Switch proxy mode
- Manage proxy groups

#### Rules

- Lihat dan kelola rules
- Add/edit/delete custom rules
- Reorder rules priority

#### Connections

- Monitor active connections
- Lihat detail per-connection
- Close connections

#### Hotspot

- Start/stop hotspot
- Monitor connected clients
- Configure SSID/password

#### Interfaces

- Lihat network interfaces
- Monitor interface status
- IP address management

#### Traffic Monitor

- Real-time bandwidth usage
- Historical data
- Per-connection breakdown

#### Settings

- Change login credentials
- Configure Mihomo ports
- Backup/restore config

#### Logs

- View system logs
- Mihomo logs
- Debug information

---

## 7. Tips & Troubleshooting

### Monitoring

```bash
# Real-time monitor
sudo bash scripts/monitor.sh

# Simple stats
sudo bash scripts/monitor.sh stats

# Test connectivity
sudo bash scripts/monitor.sh test
```

### Check Logs

```bash
# Mihomo logs
sudo tail -f /var/log/mihomo/mihomo.log

# Systemd logs
sudo journalctl -u mihomo -f

# Last 50 lines
sudo journalctl -u mihomo -n 50
```

### Common Issues

#### 1. Mihomo tidak start

```bash
# Check logs
sudo journalctl -u mihomo -n 50

# Test config syntax
sudo /opt/mihomo/mihomo -t -d /etc/mihomo -f /etc/mihomo/config.yaml

# Check permissions
ls -la /etc/mihomo/

# Try manual start
sudo /opt/mihomo/mihomo -d /etc/mihomo -f /etc/mihomo/config.yaml
```

#### 2. Proxy tidak connect

```bash
# Test manual
curl -v -x http://127.0.0.1:7890 https://www.google.com

# Check external controller
curl http://127.0.0.1:9090/version

# Check proxies
curl http://127.0.0.1:9090/proxies

# Reload config
sudo systemctl restart mihomo
```

#### 3. Web UI tidak bisa kontrol system

```bash
# Check sudoers
sudo cat /etc/sudoers | grep www-data

# Check PHP error log
sudo tail -f /var/log/apache2/error.log

# Test sudo as www-data
sudo -u www-data sudo systemctl status mihomo
```

#### 4. Hotspot tidak muncul

```bash
# Check WiFi interface
ip link show

# Kill processes yang pakai WiFi
sudo killall wpa_supplicant

# Check RF kill
sudo rfkill list
sudo rfkill unblock wifi

# Manual start
sudo hostapd /etc/hostapd/hostapd.conf
```

#### 5. Client tidak bisa internet

```bash
# Check IP forwarding
sysctl net.ipv4.ip_forward

# Check iptables
sudo iptables -t nat -L -n -v

# Check routing
ip route

# Re-apply routing
sudo bash scripts/routing.sh setup
```

### Performance Tips

1. **Untuk koneksi lebih cepat:**

   - Gunakan mode `url-test` untuk auto-select proxy tercepat
   - Enable `store-selected` dan `store-fake-ip`
   - Gunakan DNS over HTTPS

2. **Untuk stability:**

   - Enable health-check untuk proxy providers
   - Set fallback proxies
   - Monitor logs regularly

3. **Untuk security:**
   - Ganti default password
   - Gunakan strong secret key
   - Enable HTTPS untuk Web UI
   - Firewall external controller port

### Advanced Configuration

#### Setup HTTPS untuk Web UI

```bash
# Install certbot
sudo apt install certbot python3-certbot-apache

# Generate SSL certificate
sudo certbot --apache -d your-domain.com

# Auto-renewal sudah di-setup oleh certbot
```

#### Custom DNS

Edit `/etc/mihomo/config.yaml`:

```yaml
dns:
  nameserver:
    - https://dns.google/dns-query
    - https://cloudflare-dns.com/dns-query
  fallback:
    - https://1.1.1.1/dns-query
```

#### Bandwidth Limiting

Gunakan `tc` untuk limit bandwidth per interface:

```bash
# Limit upload ke 10Mbps
sudo tc qdisc add dev eth1 root tbf rate 10mbit burst 32kbit latency 400ms

# Remove limit
sudo tc qdisc del dev eth1 root
```

### Backup & Restore

#### Backup

```bash
# Backup config
sudo tar -czf mihomo-backup-$(date +%Y%m%d).tar.gz /etc/mihomo/

# Backup dengan web UI
sudo tar -czf mihomo-full-backup-$(date +%Y%m%d).tar.gz /etc/mihomo/ /var/www/html/mihomo-ui/
```

#### Restore

```bash
# Extract backup
sudo tar -xzf mihomo-backup-20240101.tar.gz -C /

# Restart service
sudo systemctl restart mihomo
```

### Update Mihomo

```bash
# Download versi terbaru
cd /opt/mihomo
sudo wget https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-latest.gz

# Backup binary lama
sudo mv mihomo mihomo.old

# Extract dan set permission
sudo gunzip mihomo-linux-amd64-latest.gz
sudo mv mihomo-linux-amd64-latest mihomo
sudo chmod +x mihomo

# Restart service
sudo systemctl restart mihomo

# Check version
./mihomo -v
```

---

## 📝 Checklist Setelah Instalasi

- [ ] Mihomo service running (`systemctl status mihomo`)
- [ ] Proxy bisa diakses (`curl -x http://127.0.0.1:7890 https://google.com`)
- [ ] Web UI bisa diakses dan login
- [ ] IP forwarding enabled
- [ ] Routing/iptables configured
- [ ] Hotspot running (optional)
- [ ] Client bisa connect dan internet working
- [ ] Password default sudah diganti
- [ ] Backup konfigurasi sudah dibuat

---

## 🎯 Next Steps

1. **Optimize Rules**: Customize rules sesuai kebutuhan Anda
2. **Add More Proxies**: Tambah proxy dari subscription atau manual
3. **Monitor Usage**: Pantau penggunaan bandwidth dan traffic
4. **Secure System**: Ganti password, enable firewall
5. **Auto-Update**: Setup cron untuk update providers

---

## 📞 Support

Jika ada masalah:

1. Check logs: `sudo journalctl -u mihomo -n 100`
2. Test manual: Command-command di troubleshooting section
3. Review konfigurasi: Pastikan syntax YAML benar

---

**Selamat! Laptop Debian Anda sekarang sudah menjadi Gateway seperti OpenWRT dengan OpenClash! 🎉**
