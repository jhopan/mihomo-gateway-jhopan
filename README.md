# 🚀 Mihomo Gateway

![Version](https://img.shields.io/badge/Version-2.1-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Status](https://img.shields.io/badge/Status-Production-success)

**Transparent Proxy Gateway dengan WiFi Hotspot**

Solusi lengkap untuk membuat WiFi hotspot dengan automatic proxy routing menggunakan Mihomo (Clash Meta).

---

## ⚡ Quick Start

```bash
# Clone repository
cd /opt
git clone https://github.com/jhopan/mihomo-gateway-jhopan.git mihomo-gateway
cd mihomo-gateway

# Install
sudo bash install.sh

# Start hotspot
sudo bash scripts/hotspot.sh start
```

**Connect ke WiFi:**

- SSID: `Mihomo-Gateway`
- Password: `mihomo2024`
- Gateway: `192.168.1.1`

---

## ✨ Features

✅ **WiFi Hotspot** - Automatic AP mode dengan WPA2  
✅ **Transparent Proxy** - Mihomo (Clash Meta) untuk routing  
✅ **Web UI** - Control panel untuk management  
✅ **Auto Detection** - USB tethering & WiFi interface  
✅ **Client Monitor** - Real-time monitoring connected devices  
✅ **Multiple Methods** - TUN dan REDIRECT support  
✅ **Watchdog** - Auto-restart jika hotspot down

---

## 📋 Requirements

- **OS:** Debian/Ubuntu Linux
- **WiFi Card:** Support AP mode
- **Internet:** USB tethering atau ethernet
- **Packages:** hostapd, dnsmasq, iptables, php, nginx

---

## 🎛️ Control Commands

```bash
# Hotspot control
sudo bash scripts/hotspot.sh start    # Start hotspot
sudo bash scripts/hotspot.sh stop     # Stop hotspot
sudo bash scripts/hotspot.sh restart  # Restart hotspot
sudo bash scripts/hotspot.sh status   # Check status

# Mihomo control
sudo systemctl start mihomo           # Start proxy
sudo systemctl stop mihomo            # Stop proxy
sudo systemctl restart mihomo         # Restart proxy
sudo systemctl status mihomo          # Check status
```

---

## 🌐 Web UI Setup

```bash
# Install web server
sudo apt update
sudo apt install -y nginx php-fpm php-cli php-json

# Setup WebUI
sudo cp -r webui/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/

# Configure Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80 default_server;
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

# Start services
sudo systemctl restart nginx php8.2-fpm
sudo systemctl enable nginx php8.2-fpm
```

**Access WebUI:** `http://192.168.1.1`

**Default Login:**

- Username: `admin`
- Password: `mihomo2024`

---

## 📊 WebUI Features

| Feature                 | Description                              |
| ----------------------- | ---------------------------------------- |
| 📊 **Dashboard**        | Status hotspot, clients, traffic monitor |
| ⚙️ **Hotspot Settings** | Change channel, SSID, password           |
| 👥 **Client Monitor**   | View connected devices, block/unblock    |
| 🔧 **Proxy Config**     | Upload config, edit providers            |
| 📈 **Speedtest**        | Test speed per channel                   |

---

## 🔧 Configuration

### WiFi Settings

Edit `/etc/hostapd/hostapd.conf`:

```conf
interface=wlp2s0
ssid=Mihomo-Gateway
channel=6
wpa_passphrase=mihomo2024
```

**Recommended Channels:** 1, 6, 11 (non-overlapping)

### Mihomo Config

Edit `/opt/mihomo-gateway/config/config.yaml`:

```yaml
tun:
  enable: true
  stack: system
  dns-hijack:
    - any:53
```

**Config Locations:**

- Main: `config/config.yaml`
- Game: `config/game.yaml`
- Providers: `config/proxy-providers/`

---

## 🛠️ Troubleshooting

### Hotspot tidak start

```bash
# Check interfaces
sudo bash scripts/detect-interfaces.sh

# Check power saving (MUST BE OFF)
sudo /usr/sbin/iw dev wlp2s0 get power_save

# Disable power saving
sudo /usr/sbin/iw dev wlp2s0 set power_save off
```

### Client tidak bisa connect

```bash
# Check hostapd logs
sudo journalctl -u hostapd -n 50

# Restart with clean state
sudo bash scripts/hotspot.sh stop
sudo rfkill unblock wifi
sudo bash scripts/hotspot.sh start
```

### Tidak ada internet

```bash
# Check USB tethering
ip link show | grep enx

# Check NAT rules
sudo iptables -t nat -L -n -v

# Reset routing
sudo bash scripts/routing.sh
```

### Full Diagnostic

```bash
sudo bash diagnose.sh
```

---

## 📁 Project Structure

```
mihomo-gateway/
├── config/              # Mihomo configurations
│   ├── config.yaml      # Main config
│   ├── game.yaml        # Game optimized
│   └── proxy-providers/ # Proxy lists
├── scripts/
│   ├── hotspot.sh       # Main hotspot control ⭐
│   ├── detect-interfaces.sh
│   ├── client-monitor.sh
│   ├── routing.sh
│   └── setup.sh
├── webui/               # Web control panel
│   ├── index.php
│   ├── api.php
│   └── dashboard/
├── install.sh           # Installation script
├── diagnose.sh          # Diagnostic tool
├── README.md            # This file
└── SETUP.md             # Complete setup guide
```

---

## 🎯 Performance Tips

**For Best Speed:**

- ✅ Use channel 6 (most stable)
- ✅ Disable WiFi power saving
- ✅ Use USB 3.0 for tethering
- ✅ Enable QoS/WMM

**For Gaming:**

- ✅ Use `game.yaml` config
- ✅ Enable TUN mode
- ✅ Use low latency proxy
- ✅ Direct connection for game servers

**For Phone:**

- ✅ Disable MAC randomization
- ✅ Forget & reconnect if unstable
- ✅ Keep WiFi always on

---

## 📝 Important Notes

- **WiFi Power Saving:** Harus dimatikan! (`iw dev wlp2s0 set power_save off`)
- **MAC Randomization:** Disable di phone untuk koneksi stabil
- **Channel:** 6 adalah default (tested paling stabil)
- **HT40:** Enabled untuk speed 2x lipat (40 MHz vs 20 MHz)

---

## 🚀 Auto Start on Boot

Services sudah di-enable otomatis:

```bash
sudo systemctl enable mihomo      # ✅ Auto-enabled
sudo systemctl enable hostapd     # ✅ Auto-enabled
sudo systemctl enable dnsmasq     # ✅ Auto-enabled
```

Hotspot akan start otomatis setelah boot.

---

## 📖 Documentation

- **[SETUP.md](SETUP.md)** - Complete installation & setup guide
- **[LICENSE](LICENSE)** - MIT License

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open pull request

---

## 📞 Support

**Issues?** Check:

1. Run `sudo bash diagnose.sh`
2. Check logs: `sudo journalctl -u hostapd -n 50`
3. Verify power saving OFF
4. Test different channel

---

## ⚖️ License

MIT License - See [LICENSE](LICENSE) file

---

## 🎉 Quick Commands

```bash
# Start everything
sudo bash scripts/hotspot.sh start && sudo systemctl start mihomo

# Stop everything
sudo bash scripts/hotspot.sh stop && sudo systemctl stop mihomo

# Status check
sudo bash scripts/hotspot.sh status
sudo systemctl status mihomo

# WebUI
# http://192.168.1.1
```

---

**Made with ❤️ for easy network management**
