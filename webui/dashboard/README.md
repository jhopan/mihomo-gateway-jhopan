# 📊 Mihomo Dashboard

Folder ini untuk menyimpan file dashboard Mihomo Web UI.

## 📥 Download Dashboard

Pilih salah satu dashboard favorit kamu:

### 1. **MetaCubeX/Yacd-meta** (Recommended)

```bash
cd /var/www/html/mihomo-ui/dashboard
wget https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip
unzip gh-pages.zip
mv Yacd-meta-gh-pages/* .
rm -rf Yacd-meta-gh-pages gh-pages.zip
```

### 2. **Metacubexd** (Modern UI)

```bash
cd /var/www/html/mihomo-ui/dashboard
wget https://github.com/MetaCubeX/metacubexd/archive/gh-pages.zip
unzip gh-pages.zip
mv metacubexd-gh-pages/* .
rm -rf metacubexd-gh-pages gh-pages.zip
```

### 3. **Razord** (Minimal)

```bash
cd /var/www/html/mihomo-ui/dashboard
wget https://github.com/Metacubex/Razord/archive/gh-pages.zip
unzip gh-pages.zip
mv Razord-gh-pages/* .
rm -rf Razord-gh-pages gh-pages.zip
```

### 4. **Dashboard Zashboard** (Alternative)

```bash
cd /var/www/html/mihomo-ui/dashboard
wget https://github.com/Zephyruso/zashboard/archive/gh-pages.zip
unzip gh-pages.zip
mv zashboard-gh-pages/* .
rm -rf zashboard-gh-pages gh-pages.zip
```

## 🔄 Ganti Dashboard

Gampang! Tinggal hapus isi folder ini, terus download dashboard baru:

```bash
# Backup dulu (opsional)
cd /var/www/html/mihomo-ui
mv dashboard dashboard.backup

# Buat folder baru
mkdir dashboard
cd dashboard

# Download dashboard baru (pilih salah satu dari list di atas)
```

## 🌐 Akses Dashboard

Setelah download, buka browser:

```
http://192.168.1.1/mihomo-ui/dashboard
```

## ⚙️ Konfigurasi

Dashboard akan otomatis connect ke Mihomo API:

- **API URL**: `http://192.168.1.1:9090`
- **Secret**: `mihomo-gateway-2024` (ganti di config.yaml)

## 📝 Notes

- Dashboard ini pure static files (HTML/CSS/JS)
- Tidak perlu install dependencies
- Bisa gonta-ganti sesuka hati
- Size dashboard biasanya < 5MB
- Pastikan nginx sudah configured untuk serve static files

## 🔗 Links

- [Yacd-meta](https://github.com/MetaCubeX/Yacd-meta)
- [Metacubexd](https://github.com/MetaCubeX/metacubexd)
- [Razord](https://github.com/Metacubex/Razord)
- [Zashboard](https://github.com/Zephyruso/zashboard)

---

**Tip**: Kalau mau coba dashboard lain, download dulu ke folder terpisah terus copy ke sini.
