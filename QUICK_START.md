# 🚀 Mihomo Gateway - Quick Start Guide

## ✨ Fitur Baru (Smart Version)

### 🎯 **Auto-Detection**

- ✅ Otomatis deteksi USB Tethering dari HP
- ✅ Otomatis deteksi interface Ethernet
- ✅ Otomatis deteksi WiFi untuk hotspot
- ✅ Prioritas: USB > Ethernet > WiFi

### 📡 **Smart WiFi Channel**

- ✅ Auto-scan channel yang available
- ✅ Pilih channel terbaik (least congested)
- ✅ Skip channel yang di-ban hardware
- ✅ Bisa manual pilih channel dari Web UI

### 🎛️ **Web Control Box**

- ✅ Atur SSID hotspot dari Web UI
- ✅ Ganti password hotspot dari Web UI
- ✅ Pilih WiFi channel dari Web UI
- ✅ Integrated Yacd Dashboard
- ✅ Integrated MetaCubeX Dashboard

### 🔧 **Smart Routing**

- ✅ iptables otomatis ter-konfigurasi
- ✅ NAT otomatis based on detected interface
- ✅ Transparent proxy auto-setup
- ✅ DNS redirect auto-configure

---

## 📦 Instalasi (One-Command)

### 1. Transfer Project ke Debian

```bash
# Via USB/Copy langsung
# Copy folder mihomo-gateway ke Debian Anda
```

### 2. Jalankan Instalasi Otomatis

```bash
cd mihomo-gateway/scripts
sudo bash setup.sh
```

Script akan otomatis:

- Download Mihomo binary
- Install dependencies
- Setup systemd service
- Install Web UI
- Configure permissions

---

## 🚀 Quick Start (Super Mudah!)

### Cara Tercepat - All-in-One Script

```bash
cd mihomo-gateway/scripts
sudo bash smart-setup.sh
```

Script ini akan OTOMATIS:

1. ✅ Detect interface internet (USB/Ethernet/WiFi)
2. ✅ Setup routing & iptables
3. ✅ Start Mihomo service
4. ✅ Setup & start WiFi hotspot
5. ✅ Tampilkan semua info yang diperlukan

**SELESAI!** Dalam 1-2 menit semua sudah jalan!

---

## 📱 Koneksi dengan USB Tethering

### Android:

1. Colokkan HP ke laptop via USB
2. Settings > Network > USB Tethering > Enable
3. Interface `usb0` atau `rndis0` akan muncul
4. Script otomatis detect!

### iPhone:

1. Colokkan iPhone ke laptop via USB
2. Settings > Personal Hotspot > Enable
3. Interface akan otomatis muncul
4. Script otomatis detect!

**Tidak perlu konfigurasi manual!** Script deteksi otomatis!

---

## 🎯 Cara Pakai

### 1. **Start Semua (Otomatis)**

```bash
cd mihomo-gateway/scripts
sudo bash smart-setup.sh
```

### 2. **Manual Control (Per Komponen)**

#### Check Interface

```bash
sudo bash detect-interfaces.sh detect
```

#### Setup Routing

```bash
sudo bash routing.sh setup
```

#### Start Hotspot

```bash
sudo bash hotspot.sh start
```

#### Monitor System

```bash
sudo bash monitor.sh
```

---

## 🌐 Akses Web UI

```
http://IP-SERVER/mihomo-ui
```

**Dari Hotspot:**

```
http://192.168.100.1/mihomo-ui
```

**Login:**

- Username: `admin`
- Password: `admin123`

---

## ⚙️ Konfigurasi dari Web UI

### 📡 **Hotspot Settings**

1. Login ke Web UI
2. Klik menu **Hotspot**
3. Scroll ke **Hotspot Configuration**
4. Atur:
   - **SSID**: Nama WiFi
   - **Password**: Min 8 karakter
   - **Channel**: Auto (recommended) atau manual
5. Klik **Save Configuration**
6. Restart hotspot jika perlu

### 🎛️ **External Dashboard**

1. Login ke Web UI
2. Klik menu **External Dashboard**
3. Pilih:
   - **Yacd**: Simple & clean
   - **MetaCubeX**: Advanced features
4. Dashboard langsung muncul di iframe!

**Atau buka di tab baru:**

```
https://yacd.haishan.me/?hostname=IP-SERVER&port=9090
https://metacubex.github.io/yacd/?hostname=IP-SERVER&port=9090
```

---

## 🔧 Konfigurasi Proxy

### Cara 1: Edit Config Manual

```bash
sudo nano /etc/mihomo/proxies/custom.yaml
```

Tambahkan proxy:

```yaml
proxies:
  - name: "Server 1"
    type: vmess
    server: your-server.com
    port: 443
    uuid: your-uuid
    alterId: 0
    cipher: auto
    tls: true
```

Restart:

```bash
sudo systemctl restart mihomo
```

### Cara 2: Subscription URL

```bash
sudo nano /etc/mihomo/config.yaml
```

Edit `proxy-providers`:

```yaml
proxy-providers:
  provider1:
    type: http
    url: "YOUR-SUBSCRIPTION-URL"
    interval: 3600
    path: /etc/mihomo/proxies/provider1.yaml
```

Restart:

```bash
sudo systemctl restart mihomo
```

---

## 📊 Monitoring

### Real-time Monitor

```bash
sudo bash scripts/monitor.sh
```

Akan menampilkan:

- Traffic speed (upload/download)
- Active connections
- System resources
- Hotspot clients

### Check Logs

```bash
sudo journalctl -u mihomo -f
```

### Test Connection

```bash
# Direct test
curl -x http://127.0.0.1:7890 https://www.google.com

# Check IP
curl -x http://127.0.0.1:7890 https://api.ipify.org
```

---

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

### Change Hotspot SSID/Password

**Via Web UI** (Recommended):

1. Web UI > Hotspot > Hotspot Configuration
2. Edit SSID/Password
3. Save

**Via Command:**

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

### Manual Select WiFi Channel

```bash
sudo bash scripts/smart-channel.sh wlan0 select 6
```

---

## 🐛 Troubleshooting

### 1. Interface Tidak Terdeteksi

```bash
# Manual check
ip addr show

# Force detection
sudo bash scripts/detect-interfaces.sh detect

# Check detection result
cat /tmp/mihomo-interfaces.conf
```

### 2. Hotspot Tidak Start

```bash
# Check WiFi support
iw list | grep "Supported interface modes" -A 8

# Check channel availability
sudo bash scripts/smart-channel.sh wlan0 info

# Manual start
sudo systemctl start hostapd
sudo journalctl -u hostapd -n 50
```

### 3. Proxy Tidak Connect

```bash
# Check Mihomo status
sudo systemctl status mihomo

# Check API
curl http://127.0.0.1:9090/version

# Check config
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

---

## 💡 Tips & Tricks

### 1. **Auto-Start on Boot**

Semua sudah auto-start! Tapi jika perlu manual:

```bash
sudo systemctl enable mihomo
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq
```

### 2. **Best Channel for 2.4GHz**

Channel 1, 6, atau 11 (non-overlapping)

Auto-select akan pilih yang terbaik!

### 3. **Optimize for Speed**

Edit `/etc/mihomo/config.yaml`:

```yaml
mode: rule # Tidak perlu global
dns:
  enhanced-mode: fake-ip # Lebih cepat
```

### 4. **USB Tethering Battery Saving**

Di HP:

- Gunakan mode "Charging only" lalu enable tethering
- Atau disable WiFi di HP saat tethering

### 5. **Multiple Devices**

Semua device di hotspot otomatis pakai proxy!
Tidak perlu setting di device masing-masing!

---

## 📋 Checklist Setup

- [ ] USB Tethering connected & internet OK
- [ ] `sudo bash smart-setup.sh` executed
- [ ] Mihomo running (`systemctl status mihomo`)
- [ ] Hotspot started & visible
- [ ] Web UI accessible
- [ ] Password changed from default
- [ ] Proxy configured
- [ ] Test connection: `curl -x http://127.0.0.1:7890 https://google.com`
- [ ] Client connect to hotspot & internet works
- [ ] Dashboard working (Yacd/MetaCubeX)

---

## 🎉 Done!

**Laptop Debian Anda sekarang adalah:**

- 🚀 Gateway seperti OpenWRT
- 📡 WiFi Hotspot dengan smart channel
- 🌐 Transparent Proxy untuk semua client
- 🎛️ Control via Web UI
- 📊 Monitoring real-time
- 🔄 Auto-detect USB tethering

**Semua dalam 1-2 menit setup!**

---

## 📞 Quick Reference

| Service              | Command                                  |
| -------------------- | ---------------------------------------- |
| **Start All**        | `sudo bash scripts/smart-setup.sh`       |
| **Check Status**     | `systemctl status mihomo`                |
| **View Logs**        | `journalctl -u mihomo -f`                |
| **Monitor**          | `bash scripts/monitor.sh`                |
| **Hotspot Start**    | `sudo bash scripts/hotspot.sh start`     |
| **Hotspot Stop**     | `sudo bash scripts/hotspot.sh stop`      |
| **Detect Interface** | `sudo bash scripts/detect-interfaces.sh` |
| **Re-apply Routes**  | `sudo bash scripts/routing.sh setup`     |

---

**Happy Gateway-ing! 🚀**
