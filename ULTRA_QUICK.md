# 🚀 Mihomo Gateway - Ultra Quick Guide

## Setup dalam 3 Langkah!

### 1️⃣ Connect USB Tethering

```
📱 HP Android: Settings > USB Tethering > ON
📱 HP iPhone: Settings > Personal Hotspot > ON
```

### 2️⃣ Run Smart Setup

```bash
cd mihomo-gateway/scripts
sudo bash smart-setup.sh
```

### 3️⃣ Done! ✅

```
🌐 Web UI: http://192.168.100.1/mihomo-ui
👤 Login: admin / admin123
📊 Dashboard: Menu > External Dashboard
```

---

## 📱 Akses dari HP/Laptop Lain

1. **Connect ke WiFi Hotspot**

   - SSID: Lihat di output smart-setup.sh (default: Mihomo-Gateway)
   - Password: Lihat di output (default: mihomo123)

2. **Buka Browser**

   ```
   http://192.168.100.1/mihomo-ui
   ```

3. **Semua Traffic Otomatis Pakai Proxy!**
   - Tidak perlu setting apapun di HP/Laptop
   - Langsung browsing seperti biasa

---

## 🎛️ Atur Hotspot dari Web UI

1. Login Web UI
2. Klik menu **Hotspot**
3. Scroll ke **Hotspot Configuration**
4. Edit:
   - SSID: Nama WiFi kamu
   - Password: Min 8 karakter
   - Channel: Biarkan Auto (recommended)
5. Klik **Save Configuration**
6. Restart hotspot jika perlu

---

## 🌐 Pakai Dashboard External

1. Login Web UI
2. Klik menu **External Dashboard**
3. Pilih:
   - **Yacd** = Simple, mudah dipahami
   - **MetaCubeX** = Advanced, banyak fitur
4. Dashboard langsung muncul!

Dari sini bisa:

- Ganti proxy
- Atur rules
- Lihat traffic real-time
- Test proxy speed

---

## 🔧 Command Penting

```bash
# Monitor real-time
sudo bash scripts/monitor.sh

# Check status
systemctl status mihomo

# Restart semua
sudo systemctl restart mihomo
sudo bash scripts/hotspot.sh restart

# Detect ulang interface
sudo bash scripts/detect-interfaces.sh detect

# Ganti SSID/Password via command
sudo bash scripts/hotspot.sh change-ssid "NamaBarumu"
sudo bash scripts/hotspot.sh change-password "password123"
sudo bash scripts/hotspot.sh restart
```

---

## 🐛 Troubleshooting Cepat

### Hotspot tidak muncul?

```bash
# Check WiFi support
iw list | grep "AP"

# Restart hotspot
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq
```

### Client connect tapi tidak ada internet?

```bash
# Re-apply routing
sudo bash scripts/routing.sh setup

# Check IP forwarding
sysctl net.ipv4.ip_forward
```

### USB tethering tidak terdeteksi?

```bash
# Check interface
ip addr show | grep -E "usb|rndis"

# Force detect
sudo bash scripts/detect-interfaces.sh detect
```

---

## 📚 Dokumentasi Lengkap

Butuh info lebih detail? Baca:

- **[QUICK_START.md](QUICK_START.md)** - Panduan lengkap step-by-step
- **[README.md](README.md)** - Overview & features
- **[COMMANDS.md](COMMANDS.md)** - Semua command reference

---

## 🎉 That's It!

**Laptop Debian kamu sekarang adalah:**

- ✅ Gateway seperti OpenWRT
- ✅ WiFi Hotspot pintar
- ✅ Transparent Proxy otomatis
- ✅ Control via Web UI
- ✅ Dashboard Yacd & MetaCubeX

**Setup cuma 1-2 menit!** 🚀

---

## 💡 Tips

1. **Ganti password default** di Web UI segera
2. **Simpan SSID & password** hotspot kamu
3. **Bookmark Web UI** di browser: `http://192.168.100.1/mihomo-ui`
4. **Test proxy** dengan: `curl -x http://127.0.0.1:7890 https://google.com`
5. **Monitor traffic** dengan script: `sudo bash scripts/monitor.sh`

---

**Happy Surfing! 🏄‍♂️**
