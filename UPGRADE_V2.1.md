# 🎉 Mihomo Gateway v2.1.0 - Enhanced Configuration

## ✨ Major Updates

### 🔧 Configuration Structure

✅ **Standard Naming Convention**

- `proxy-providers` → `proxy_providers/` folder
- `rule-providers` → `rule_providers/` folder
- Clean, organized structure

### 🌐 Network Configuration

✅ **Easy to Remember IP**

- Web UI: **192.168.1.1** (gampang diingat!)
- Hotspot Network: 192.168.1.0/24
- DHCP Range: 192.168.1.10 - 192.168.1.100

### 🚀 Multiple Proxy Methods

✅ **TUN Mode (Default - Recommended)**

- Kernel-level transparent proxy
- Best performance
- Works with all apps
- Device: `utun` or `tun0`

✅ **REDIRECT Mode**

- iptables-based redirect
- TCP only
- Lower overhead

✅ **TPROXY Mode**

- Advanced transparent proxy
- TCP + UDP support
- For power users

### 🛡️ Service Protection

✅ **Safe for Existing Services**

- ✅ SSH (port 22, 2222) - Always direct
- ✅ Tailscale (network 100.64.0.0/10) - Never proxied
- ✅ Docker (networks 172.17-20.0.0/16) - Isolated
- ✅ CasaOS (port 8080) - Protected
- ✅ Web UI (port 80, 443) - Direct access
- ✅ Bots & Services - Won't be affected

### 📁 File Manager

✅ **Built-in File Manager**

- Web-based file editing
- Direct access to `/etc/mihomo`
- Edit config files easily
- No need SSH for simple edits!

---

## 📂 New Folder Structure

```
mihomo-gateway/
├── config/
│   ├── config.yaml                    # Main config (updated!)
│   ├── proxy_providers/               # NEW naming!
│   │   ├── custom.yaml               # Manual proxies
│   │   ├── subscription.yaml         # Auto-download
│   │   └── backup.yaml               # Backup servers
│   └── rule_providers/                # NEW naming!
│       ├── custom.yaml               # Your rules
│       ├── streaming.yaml            # Streaming services
│       ├── gaming.yaml               # Gaming platforms
│       ├── social.yaml               # Social media
│       └── reject.yaml               # Auto-download (ads/trackers)
│
└── scripts/
    ├── routing-enhanced.sh            # NEW! Safe routing
    ├── hotspot.sh                     # Updated IP (192.168.1.1)
    └── ...

└── webui/
    ├── filemanager.php                # NEW! File manager
    └── ...
```

---

## 🚀 Quick Start

### 1️⃣ Update Configuration

```bash
cd mihomo-gateway

# Backup old config (if you have custom settings)
sudo cp /etc/mihomo/config.yaml /etc/mihomo/config.yaml.backup

# Copy new config structure
sudo cp config/config.yaml /etc/mihomo/
sudo cp -r config/proxy_providers /etc/mihomo/
sudo cp -r config/rule_providers /etc/mihomo/

# Set permissions
sudo chown -R mihomo:mihomo /etc/mihomo
```

### 2️⃣ Update Scripts

```bash
# Copy enhanced routing script
sudo cp scripts/routing-enhanced.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/routing-enhanced.sh

# Update hotspot script (new IP)
sudo cp scripts/hotspot.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/hotspot.sh
```

### 3️⃣ Setup Routing (Safe Mode)

```bash
# Setup with TUN method (default, recommended)
sudo bash /usr/local/bin/routing-enhanced.sh setup

# Or specific method:
# sudo bash /usr/local/bin/routing-enhanced.sh tun
# sudo bash /usr/local/bin/routing-enhanced.sh redirect
# sudo bash /usr/local/bin/routing-enhanced.sh tproxy
```

### 4️⃣ Restart Services

```bash
# Stop hotspot
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Restart Mihomo
sudo systemctl restart mihomo

# Start hotspot with new IP
sudo bash /usr/local/bin/hotspot.sh start
```

### 5️⃣ Access Web UI

```
📱 From Hotspot:    http://192.168.1.1
🌐 From Network:    http://YOUR-SERVER-IP/mihomo-ui
```

**Login:** `admin` / `admin123`

---

## 📁 File Manager Usage

### Access File Manager

1. Login to Web UI
2. Click **📁 File Manager** in sidebar
3. Browse `/etc/mihomo` directory
4. Edit files directly in browser!

### What You Can Do

✅ **Edit Configuration**

- config.yaml
- proxy_providers/\*.yaml
- rule_providers/\*.yaml

✅ **View Files**

- Browse all Mihomo configs
- Check file sizes
- Download files

✅ **Quick Edit**

- No SSH needed
- Syntax highlighting
- Save directly

### Security

- 🔒 Restricted to `/etc/mihomo` only
- 🔒 Requires authentication
- 🔒 Same login as main UI

---

## 🎛️ Configuration Guide

### Add Custom Proxy

1. **Via File Manager:**

   - Open File Manager
   - Navigate to `proxy_providers/`
   - Edit `custom.yaml`
   - Add your proxy server
   - Save
   - Restart Mihomo

2. **Or via SSH:**
   ```bash
   sudo nano /etc/mihomo/proxy_providers/custom.yaml
   # Add proxy, save
   sudo systemctl restart mihomo
   ```

### Add Subscription URL

Edit `/etc/mihomo/config.yaml`:

```yaml
proxy-providers:
  subscription_provider:
    type: http
    url: "YOUR-SUBSCRIPTION-URL-HERE"
    interval: 3600
    path: /etc/mihomo/proxy_providers/subscription.yaml
```

Restart:

```bash
sudo systemctl restart mihomo
```

### Add Custom Rules

1. Open File Manager
2. Edit `rule_providers/custom.yaml`
3. Add rules:
   ```yaml
   payload:
     - DOMAIN-SUFFIX,example.com
     - DOMAIN-KEYWORD,blocked
     - IP-CIDR,1.2.3.4/24
   ```
4. Save and restart

---

## 🔒 Security Features

### Protected Services

Your existing services are **100% safe**:

```
✅ SSH (22, 2222)           → Never proxied
✅ Tailscale (41641)        → Direct connection
✅ Docker containers        → Isolated
✅ CasaOS (8080)           → Direct access
✅ Web servers (80, 443)    → Local access
✅ Mihomo API (9090)        → Protected
✅ Bots & Services          → Won't be affected
```

### Network Isolation

```
Protected Networks (Always Direct):
- 127.0.0.0/8        # Localhost
- 10.0.0.0/8         # Private
- 172.16.0.0/12      # Private
- 192.168.0.0/16     # Private
- 100.64.0.0/10      # Tailscale CGNAT
- 172.17-20.0.0/16   # Docker networks
```

---

## 🎮 Proxy Methods Explained

### TUN Method (Default) ✅

**Best for most users!**

```bash
sudo bash routing-enhanced.sh tun
```

**Advantages:**

- ✅ Works at kernel level
- ✅ Supports all protocols (TCP, UDP, ICMP)
- ✅ Best performance
- ✅ Per-app proxy support
- ✅ Most compatible

**How it works:**

- Creates virtual network interface (`utun`)
- Routes traffic through TUN device
- Mihomo processes at kernel level
- No iptables redirect needed

### REDIRECT Method

**Good for simple TCP proxy**

```bash
sudo bash routing-enhanced.sh redirect
```

**Advantages:**

- ✅ Simple iptables-based
- ✅ Lower overhead
- ✅ Works on old kernels

**Limitations:**

- ❌ TCP only (no UDP)
- ❌ Higher latency than TUN

### TPROXY Method

**For advanced users**

```bash
sudo bash routing-enhanced.sh tproxy
```

**Advantages:**

- ✅ TCP + UDP support
- ✅ True transparent proxy
- ✅ Preserves source IP

**Limitations:**

- ❌ Complex setup
- ❌ Requires kernel support
- ❌ May conflict with some services

---

## 🔧 Troubleshooting

### Web UI Not Accessible at 192.168.1.1

```bash
# Check hotspot IP
ip addr show wlan0

# Restart hotspot
sudo bash /usr/local/bin/hotspot.sh restart

# Check firewall
sudo iptables -L INPUT -n | grep 80
```

### SSH Still Works?

Yes! SSH is protected:

```bash
# Check SSH rules
sudo iptables -L INPUT -n | grep 22
```

### Tailscale Not Working?

Tailscale is bypassed:

```bash
# Check bypass rules
sudo iptables -t nat -L MIHOMO_BYPASS -n
```

### Docker Containers Affected?

No, Docker networks are isolated:

```bash
# Verify Docker bypass
sudo iptables -t nat -L MIHOMO_BYPASS -n | grep 172.
```

### TUN Device Not Created?

```bash
# Check Mihomo logs
sudo journalctl -u mihomo -n 50

# Verify TUN config
sudo nano /etc/mihomo/config.yaml
# Make sure tun.enable: true
```

---

## 📊 Comparison: v2.0 vs v2.1

| Feature                | v2.0          | v2.1 (NEW!)                        |
| ---------------------- | ------------- | ---------------------------------- |
| **Config Naming**      | Mixed         | ✅ Standard (provider\_\*)         |
| **IP Address**         | 192.168.100.1 | ✅ 192.168.1.1 (easy!)             |
| **Proxy Method**       | REDIRECT only | ✅ TUN/REDIRECT/TPROXY             |
| **File Manager**       | ❌ None       | ✅ Built-in web UI                 |
| **Service Protection** | Basic         | ✅ Complete (SSH/Tailscale/Docker) |
| **iptables Safety**    | Basic         | ✅ Advanced bypass rules           |
| **TUN Support**        | ❌            | ✅ Default method                  |

---

## 🎯 Key Benefits

### For Regular Users

- ✅ **Easy to remember**: Just type `192.168.1.1`
- ✅ **File Manager**: Edit configs in browser
- ✅ **TUN Mode**: Best performance, works everywhere
- ✅ **Safe**: Your SSH, Tailscale, Docker won't break

### For Power Users

- ✅ **Multiple Methods**: Choose TUN/REDIRECT/TPROXY
- ✅ **Standard Naming**: proxy_providers, rule_providers
- ✅ **Advanced Rules**: Complete bypass system
- ✅ **Organized**: Clean folder structure

### For Developers/DevOps

- ✅ **No Conflicts**: Docker, CasaOS, services untouched
- ✅ **SSH Always Works**: Emergency access guaranteed
- ✅ **Tailscale Safe**: Remote access preserved
- ✅ **Bot-Friendly**: Webhooks, APIs work normally

---

## 📞 Quick Commands

```bash
# Setup routing (TUN method)
sudo bash routing-enhanced.sh setup

# Show current rules
sudo bash routing-enhanced.sh show

# Clear all rules
sudo bash routing-enhanced.sh clear

# Restart hotspot
sudo bash hotspot.sh restart

# Check Mihomo status
sudo systemctl status mihomo

# View logs
sudo journalctl -u mihomo -f

# Edit config via File Manager
# Open browser: http://192.168.1.1 → File Manager
```

---

## 🎉 Summary

**You now have:**

- ✅ Clean, standard configuration structure
- ✅ Easy to remember IP (192.168.1.1)
- ✅ TUN mode (best performance)
- ✅ Built-in file manager (no SSH needed)
- ✅ Complete service protection (SSH, Tailscale, Docker, CasaOS)
- ✅ Safe iptables rules (bots & services work fine)

**Access your gateway:**

```
Web UI:        http://192.168.1.1
File Manager:  http://192.168.1.1/filemanager.php
SSH:           ssh user@YOUR-SERVER-IP (works normally!)
Tailscale:     (works normally!)
```

**Happy Gateway-ing! 🚀**
