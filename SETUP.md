# 🚀 Quick Start Guide - Mihomo Gateway

## Setup Lengkap dari Awal

### 1️⃣ Install & Setup (Sekali Aja)

```bash
cd /opt
git clone https://github.com/jhopan/mihomo-gateway-jhopan.git mihomo-gateway
cd mihomo-gateway

# Install semua dependency
sudo bash install.sh
```

### 2️⃣ Jalankan Hotspot

```bash
# Start hotspot
sudo bash scripts/hotspot.sh start

# Check status
sudo bash scripts/hotspot.sh status

# Restart hotspot
sudo bash scripts/hotspot.sh restart

# Stop hotspot
sudo bash scripts/hotspot.sh stop
```

### 3️⃣ Setup Web UI (Control Panel)

```bash
# Install PHP & Nginx
sudo apt update
sudo apt install -y nginx php-fpm php-cli php-json

# Copy WebUI ke Nginx
sudo cp -r /opt/mihomo-gateway/webui/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/

# Setup Nginx config
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
}
EOF

# Restart services
sudo systemctl restart nginx php8.2-fpm
sudo systemctl enable nginx php8.2-fpm

echo "✅ WebUI ready at: http://192.168.1.1"
```

### 4️⃣ Akses Web UI

**Dari laptop WiFi yang connect ke hotspot:**

```
http://192.168.1.1
```

**Dari server lokal:**

```
http://localhost
```

**Login default:**

- Username: `admin`
- Password: `mihomo2024`

## 📋 Fitur Web UI

✅ **Dashboard**

- Status hotspot (on/off)
- Jumlah client connected
- Traffic monitor real-time
- CPU & Memory usage

✅ **Hotspot Control**

- Start/Stop/Restart hotspot
- Change WiFi channel (1, 6, 11)
- Change SSID & Password
- Enable/Disable TUN mode

✅ **Client Monitor**

- Daftar device connected
- IP address & MAC address
- Download/Upload speed per client
- Block/Unblock client

✅ **Proxy Config**

- Upload config.yaml
- Edit proxy providers
- Edit rule providers
- Switch between game/browsing config

✅ **Speedtest**

- Test kecepatan hotspot
- Compare antar channel
- Historical data

## 🔧 Konfigurasi Umum

### Ganti Channel WiFi

**Via Web UI:**
Dashboard → Hotspot Settings → Channel → Pilih 1/6/11 → Apply

**Via Command:**

```bash
# Edit config
sudo nano /etc/hostapd/hostapd.conf

# Ganti channel=6 ke channel yang diinginkan
# Save (Ctrl+X, Y, Enter)

# Restart hotspot
sudo bash /opt/mihomo-gateway/scripts/hotspot.sh restart
```

### Ganti SSID & Password

**Via Web UI:**
Dashboard → Hotspot Settings → SSID/Password → Apply

**Via Command:**

```bash
sudo nano /etc/hostapd/hostapd.conf

# Edit:
# ssid=Mihomo-Gateway
# wpa_passphrase=mihomo2024

sudo bash /opt/mihomo-gateway/scripts/hotspot.sh restart
```

### Update Config Mihomo

**Via Web UI:**
Dashboard → Proxy Config → Upload → Pilih file config.yaml

**Via Command:**

```bash
# Edit config
sudo nano /opt/mihomo-gateway/config/config.yaml

# Restart mihomo
sudo systemctl restart mihomo
```

## 🛠️ Tools Berguna

### Test Channel Speed

```bash
# Interactive manual test
sudo bash test-speed-manual.sh
```

### Check WiFi Capabilities

```bash
sudo bash check-wifi-capabilities.sh
```

### Diagnose Problems

```bash
sudo bash diagnose.sh
```

### Monitor Clients

```bash
# Real-time monitoring
sudo bash scripts/client-monitor.sh
```

## 📊 Status & Logs

```bash
# Hotspot status
sudo systemctl status hostapd

# DHCP status
sudo systemctl status dnsmasq

# Mihomo status
sudo systemctl status mihomo

# View hotspot logs
sudo journalctl -u hostapd -f

# View mihomo logs
sudo journalctl -u mihomo -f

# Connected clients
sudo hostapd_cli all_sta
```

## 🔥 Troubleshooting

### Hotspot tidak start

```bash
# Check interfaces
sudo bash scripts/detect-interfaces.sh

# Reset network
sudo rfkill unblock wifi
sudo ip link set wlp2s0 down
sudo ip link set wlp2s0 up

# Restart
sudo bash scripts/hotspot.sh restart
```

### Client tidak bisa connect

```bash
# Check power saving (MUST BE OFF!)
sudo /usr/sbin/iw dev wlp2s0 get power_save

# Disable power saving
sudo /usr/sbin/iw dev wlp2s0 set power_save off

# Check hostapd logs
sudo journalctl -u hostapd -n 50
```

### Tidak ada internet

```bash
# Check USB tethering
ip link show | grep enx

# Check routing
sudo bash scripts/routing.sh

# Check NAT
sudo iptables -t nat -L -n -v
```

## 🎮 Config Files Locations

```
/opt/mihomo-gateway/
├── config/
│   ├── config.yaml           # Mihomo main config
│   ├── game.yaml            # Game optimized config
│   └── proxy-providers/     # Proxy lists
├── scripts/
│   ├── hotspot.sh           # Main hotspot control
│   ├── detect-interfaces.sh # Auto-detect network
│   └── client-monitor.sh    # Monitor clients
├── webui/                   # Web control panel
└── /etc/hostapd/
    └── hostapd.conf         # WiFi AP config
```

## 🚀 Auto-Start on Boot

```bash
# Enable services
sudo systemctl enable mihomo
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq

# Hotspot will start automatically on boot
```

## 📱 Recommended Phone Settings

**Untuk koneksi stabil:**

1. Settings → WiFi → Advanced
2. **DISABLE** "Random MAC address"
3. **DISABLE** "Auto-reconnect"
4. Forget network → Reconnect manual

## ⚡ Performance Tips

**Untuk speed maksimal:**

- ✅ Channel 6 (paling stabil)
- ✅ HT40 enabled (40 MHz width)
- ✅ Power saving OFF (critical!)
- ✅ QoS/WMM enabled
- ✅ USB 3.0 tethering (biru port)

**Untuk game:**

- ✅ Pakai game.yaml config
- ✅ TUN mode enabled
- ✅ Low latency proxy
- ✅ Direct connection untuk game server

---

## 📞 Quick Commands Cheat Sheet

```bash
# Start everything
sudo bash scripts/hotspot.sh start && sudo systemctl start mihomo

# Stop everything
sudo bash scripts/hotspot.sh stop && sudo systemctl stop mihomo

# Restart everything
sudo bash scripts/hotspot.sh restart && sudo systemctl restart mihomo

# Check status
sudo bash scripts/hotspot.sh status
sudo systemctl status mihomo

# Web UI
# Open: http://192.168.1.1
```

**🎉 Done! Hotspot + WebUI siap dipakai!**
