# 🔧 Changelog v2.1.0

## 🆕 Major Changes

### ✅ Standard Naming Convention
- ✨ **proxy-providers** (bukan `proxies`)
- ✨ **rule-providers** (bukan `rules`)  
- 📁 Folder terpisah: `proxy_providers/` dan `rule_providers/`

### 🚀 Multiple Proxy Methods
- 🔄 **REDIRECT** - Method default (recommended, stabil!)
- 🧩 **TUN** - Available tapi disabled by default
- ❌ **TPROXY** - Dihapus karena sering error

### 🌐 Network Configuration
- 🎯 Gateway IP: **192.168.1.1** (gampang diingat!)
- 📱 Hotspot subnet: 192.168.1.0/24
- 🔧 DHCP range: 192.168.1.10 - 192.168.1.100

### 🛡️ Security Updates
- ✅ **Docker, CasaOS, SSH, Tailscale BISA lewat proxy** (user sudah test aman!)
- 🔒 Hanya Mihomo API (9090) yang di-bypass
- 🚫 IPv6 disabled untuk stabilitas
- 📊 Log level: warning (pantau error tanpa spam)

### 📊 Dashboard Support
- 📁 Folder dedicated: `webui/dashboard/`
- 🔄 Gampang gonta-ganti dashboard
- 📥 Download langsung dari GitHub
- 💡 Placeholder page dengan instruksi lengkap

### ⚙️ Configuration Improvements
- 🎨 Format dengan emoji & comment Indonesian
- 📝 Rules section dibersihkan (pakai rule-providers)
- 🔧 Mixed port: 7890
- 🌐 DNS: 1053 dengan extensive fake-ip filter
- 🧩 TUN: disabled by default

## 📦 New Files & Folders

```
mihomo-gateway/
├── config/
│   ├── proxy_providers/      # NEW! Provider proxy server
│   │   ├── custom.yaml
│   │   ├── subscription.yaml
│   │   └── backup.yaml
│   │
│   ├── rule_providers/       # NEW! Provider routing rules
│   │   ├── custom.yaml
│   │   ├── streaming.yaml
│   │   ├── gaming.yaml
│   │   └── social.yaml
│   │
│   └── config.yaml          # UPDATED! Format baru
│
├── webui/
│   └── dashboard/           # NEW! Dashboard folder
│       ├── README.md
│       └── index.html       # Placeholder
│
├── scripts/
│   └── routing-enhanced.sh  # UPDATED! Tanpa TPROXY
│
└── UPGRADE_V2.1.md          # NEW! Upgrade guide
```

## 🔄 Migration Notes

### From v2.0.x to v2.1.0

**Backup dulu!**
```bash
cp -r /etc/mihomo /etc/mihomo.backup
```

**Update config:**
- `proxies` → `proxy-providers`
- `rules` → `rule-providers`
- IP: 192.168.100.1 → 192.168.1.1
- Method: TUN → REDIRECT (default)

**Hapus rules untuk services:**
- Docker sekarang bisa lewat proxy
- CasaOS sekarang bisa lewat proxy
- SSH sekarang bisa lewat proxy
- Tailscale sekarang bisa lewat proxy

## ⚠️ Breaking Changes

1. **IP Gateway berubah**: 192.168.100.1 → **192.168.1.1**
2. **TPROXY dihapus**: Ganti ke REDIRECT method
3. **TUN disabled**: Gunakan REDIRECT untuk stabilitas
4. **Service bypass dihapus**: Docker/CasaOS/SSH bisa lewat proxy

## 🎯 Recommended Setup

```bash
# 1. Backup
cp -r /etc/mihomo /etc/mihomo.backup

# 2. Copy config baru
cp config/config.yaml /etc/mihomo/

# 3. Setup routing (REDIRECT method)
sudo bash scripts/routing-enhanced.sh redirect

# 4. Restart services
sudo systemctl restart mihomo
sudo systemctl restart hotspot

# 5. Download dashboard (opsional)
cd /var/www/html/mihomo-ui/dashboard
wget https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip
unzip gh-pages.zip
mv Yacd-meta-gh-pages/* .
rm -rf Yacd-meta-gh-pages gh-pages.zip
```

## 🧪 Tested Environment

- ✅ Debian 11/12
- ✅ Ubuntu 20.04/22.04/24.04
- ✅ Raspberry Pi OS
- ✅ Mihomo (Clash Meta) v1.18.0+

## 📝 Config Changes Summary

| Setting | Old (v2.0) | New (v2.1) |
|---------|-----------|-----------|
| Gateway IP | 192.168.100.1 | 192.168.1.1 |
| Proxy Method | TUN | REDIRECT |
| TPROXY | Enabled | Removed |
| IPv6 | Enabled | Disabled |
| Log Level | info | warning |
| Mixed Port | 7892 | 7890 |
| DNS Port | 5353 | 1053 |
| TUN Status | Enabled | Disabled |
| Docker Bypass | Yes | No (lewat proxy) |
| SSH Bypass | Yes | No (lewat proxy) |
| Tailscale Bypass | Yes | No (lewat proxy) |
| CasaOS Bypass | Yes | No (lewat proxy) |

## 🐛 Bug Fixes

- ❌ TPROXY crashes → Dihapus
- ✅ IPv6 instability → Disabled
- ✅ Service conflicts → Bypass rules dikurangi
- ✅ Memory leaks dengan TUN → TUN disabled by default

## 📚 Documentation

Lihat file-file berikut untuk detail:
- `UPGRADE_V2.1.md` - Upgrade guide lengkap
- `webui/dashboard/README.md` - Dashboard setup
- `config/proxy_providers/custom.yaml` - Proxy examples
- `config/rule_providers/custom.yaml` - Rules examples

## 🙏 Credits

Thanks to:
- MetaCubeX/mihomo
- Clash Meta community
- User feedback & testing

---
**Release Date**: November 17, 2025  
**Version**: v2.1.0  
**Status**: Production Ready ✅
