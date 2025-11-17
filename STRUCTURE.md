# 📁 Mihomo Gateway - Project Structure

```
mihomo-gateway/
│
├── 📄 README.md                    # Project overview & features
├── 📄 ULTRA_QUICK.md              # ⚡ 3-step quick setup guide
├── 📄 QUICK_START.md              # 📖 Complete quick start guide
├── 📄 INSTALL_GUIDE.md            # 📦 Detailed installation
├── 📄 COMMANDS.md                 # 💻 Command reference
├── 📄 COMPARISON.md               # 📊 vs OpenClash
├── 📄 CHANGELOG.md                # 🔄 Version history
├── 📄 TODO.md                     # 📋 Development roadmap
├── 📄 PROJECT_SUMMARY.md          # 📊 Project status
├── 📄 STRUCTURE.md                # This file!
├── 📄 LICENSE                     # MIT License
├── 📄 .gitignore                  # Git ignore rules
│
├── 📁 config/                     # Mihomo Configuration Files
│   ├── config.yaml                # Main Mihomo config
│   │                              # - Ports (HTTP, SOCKS5, Mixed)
│   │                              # - External controller API
│   │                              # - DNS settings (DoH, fake-ip)
│   │                              # - TUN device config
│   │                              # - Rule providers
│   │                              # - Proxy providers
│   │
│   ├── 📁 proxies/                # Proxy Definitions
│   │   ├── custom.yaml            # Custom proxy servers
│   │   └── subscription.yaml      # Subscription provider template
│   │
│   └── 📁 rules/                  # Routing Rules
│       ├── direct.yaml            # Direct connection rules
│       ├── proxy.yaml             # Proxy routing rules
│       ├── reject.yaml            # Block/reject rules
│       └── custom.yaml            # Custom routing rules
│
├── 📁 scripts/                    # Shell Scripts
│   │
│   ├── 🔧 Setup Scripts
│   │   ├── setup.sh               # Initial installation script
│   │   │                          # - Download Mihomo binary
│   │   │                          # - Install dependencies
│   │   │                          # - Setup systemd service
│   │   │                          # - Install Web UI
│   │   │
│   │   └── smart-setup.sh         # ⚡ All-in-one smart setup
│   │                              # - Auto-detect interfaces
│   │                              # - Configure routing
│   │                              # - Start Mihomo
│   │                              # - Setup hotspot
│   │                              # - Display summary
│   │
│   ├── 🌐 Network Scripts
│   │   ├── detect-interfaces.sh   # 🆕 Interface auto-detection
│   │   │                          # - USB tethering detection
│   │   │                          # - Ethernet detection
│   │   │                          # - WiFi WAN detection
│   │   │                          # - Internet connectivity check
│   │   │
│   │   ├── smart-channel.sh       # 🆕 WiFi channel management
│   │   │                          # - Channel capability detection
│   │   │                          # - Network scanning
│   │   │                          # - Channel analysis
│   │   │                          # - Best channel selection
│   │   │
│   │   ├── hotspot.sh             # 🔄 Enhanced hotspot control
│   │   │                          # - Setup with auto-detection
│   │   │                          # - Start/stop/restart
│   │   │                          # - Change SSID/password
│   │   │                          # - Show connected clients
│   │   │
│   │   └── routing.sh             # 🔄 Enhanced routing setup
│   │                              # - Auto-detect WAN interface
│   │                              # - NAT configuration
│   │                              # - Transparent proxy setup
│   │                              # - DNS redirect
│   │
│   ├── 📊 Monitoring Scripts
│   │   └── monitor.sh             # Real-time monitoring
│   │                              # - Traffic statistics
│   │                              # - Active connections
│   │                              # - System resources
│   │                              # - Hotspot clients
│   │
│   └── 🔧 Service Files
│       └── mihomo.service         # systemd service definition
│
└── 📁 webui/                      # Web User Interface
    │
    ├── 🌐 Main Files
    │   ├── index.php              # 🔄 Enhanced main dashboard
    │   │                          # - System status
    │   │                          # - Traffic monitoring
    │   │                          # - Quick actions
    │   │                          # - Hotspot config form 🆕
    │   │                          # - External dashboard 🆕
    │   │
    │   └── api.php                # 🔄 Enhanced REST API backend
    │                              # - Proxy management
    │                              # - Rules management
    │                              # - System control
    │                              # - Hotspot config endpoints 🆕
    │                              # - Stats & monitoring
    │
    ├── 📁 assets/                 # Static Assets
    │   │
    │   ├── 📁 css/
    │   │   └── style.css          # 🔄 Enhanced styling
    │   │                          # - Responsive design
    │   │                          # - Dashboard styles
    │   │                          # - Form styles 🆕
    │   │                          # - External dashboard styles 🆕
    │   │
    │   ├── 📁 js/
    │   │   └── main.js            # 🔄 Enhanced JavaScript
    │   │                          # - API calls
    │   │                          # - Real-time updates
    │   │                          # - Chart rendering
    │   │                          # - Hotspot config functions 🆕
    │   │                          # - Dashboard loader 🆕
    │   │
    │   └── 📁 images/
    │       └── logo.png           # Project logo
    │
    └── 📁 includes/               # PHP Includes
        ├── header.php             # Common page header
        └── footer.php             # Common page footer

```

---

## 🎯 Key Components Explained

### Configuration Layer (`config/`)

**Purpose:** Mihomo core configuration

- **config.yaml** - Main config with ports, DNS, TUN, providers
- **proxies/** - Proxy server definitions (vmess, vless, trojan, etc.)
- **rules/** - Routing rules (direct, proxy, reject)

### Script Layer (`scripts/`)

**Purpose:** Automation and system management

#### Smart Setup System (NEW!)

- **smart-setup.sh** - All-in-one orchestrator
- **detect-interfaces.sh** - Network interface detection
- **smart-channel.sh** - WiFi channel optimization

#### Core Scripts

- **hotspot.sh** - WiFi hotspot management (enhanced)
- **routing.sh** - iptables & routing (enhanced)
- **monitor.sh** - Real-time system monitoring

### Web UI Layer (`webui/`)

**Purpose:** User interface and control panel

#### Frontend

- **index.php** - Main dashboard UI
- **assets/css/** - Styling
- **assets/js/** - Client-side logic
- **assets/images/** - Graphics

#### Backend

- **api.php** - REST API for system control
- **includes/** - Shared PHP components

---

## 🔄 Data Flow

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │
       ├─── Connect USB Tethering
       ├─── Run smart-setup.sh
       │    │
       │    ├─► detect-interfaces.sh ──► Detect: USB/Eth/WiFi
       │    │                            Save: /tmp/mihomo-interfaces.conf
       │    │
       │    ├─► routing.sh ──► Setup: NAT, transparent proxy
       │    │                  Configure: iptables
       │    │
       │    ├─► Start Mihomo ──► Load: config.yaml
       │    │   (systemd)       Start: Proxy engine
       │    │
       │    └─► hotspot.sh ──► smart-channel.sh ──► Select best channel
       │                       Start: hostapd + dnsmasq
       │
       └─── Access Web UI ──► index.php ──► api.php ──► System Control
            (Browser)                                   ├─ Mihomo API
                                                        ├─ hostapd
                                                        └─ System commands
```

---

## 📊 Configuration Files Location (After Install)

```
System Configs:
├── /etc/mihomo/
│   ├── config.yaml                # Mihomo main config
│   ├── proxies/*.yaml             # Proxy definitions
│   └── rules/*.yaml               # Routing rules
│
├── /etc/hostapd/
│   └── hostapd.conf               # WiFi hotspot config
│
├── /etc/dnsmasq.d/
│   └── mihomo-hotspot.conf        # DHCP config
│
├── /etc/systemd/system/
│   └── mihomo.service             # systemd service
│
└── /var/www/html/
    └── mihomo-ui/                 # Web UI files

Binaries:
├── /opt/mihomo/
│   └── mihomo                     # Mihomo binary
│
└── /usr/local/bin/
    ├── detect-interfaces.sh       # Installed scripts
    ├── smart-channel.sh
    ├── smart-setup.sh
    ├── hotspot.sh
    ├── routing.sh
    └── monitor.sh

Logs:
├── /var/log/mihomo/
│   └── mihomo.log                 # Mihomo logs
│
└── journalctl -u mihomo           # systemd logs

Runtime:
└── /tmp/
    └── mihomo-interfaces.conf     # Detected interfaces cache
```

---

## 🔐 Permission Model

```
User Permissions:
├── root (sudo)
│   ├── Install & setup
│   ├── Start/stop services
│   ├── Configure network
│   └── Run system scripts
│
└── www-data (Web UI)
    ├── Read Mihomo API
    ├── Execute specific sudo commands (via sudoers)
    │   ├── systemctl (mihomo)
    │   ├── hostapd control
    │   └── Specific scripts
    └── Write to web directory

File Permissions:
├── /etc/mihomo/          - 755 root:root
├── /etc/hostapd/         - 755 root:root
├── /var/www/html/mihomo-ui/ - 755 www-data:www-data
└── Scripts in /usr/local/bin/ - 755 root:root
```

---

## 🌐 Network Architecture

```
Internet (via USB Tethering/Ethernet/WiFi)
    │
    │ [WAN Interface: usb0/eth0/wlan0]
    │
┌───▼────────────────────────────────────┐
│     Debian Laptop (Mihomo Gateway)     │
│  ┌──────────────────────────────────┐  │
│  │    Mihomo (Clash Meta)           │  │
│  │  - Transparent Proxy             │  │
│  │  - DNS (fake-ip)                 │  │
│  │  - Rule-based Routing            │  │
│  └──────────────────────────────────┘  │
│              │                          │
│  ┌───────────▼──────────────────────┐  │
│  │    iptables NAT & Routing        │  │
│  │  - PREROUTING: Redirect to proxy │  │
│  │  - POSTROUTING: NAT masquerade   │  │
│  │  - FORWARD: Allow & filter       │  │
│  └──────────────────────────────────┘  │
└────────────────┬───────────────────────┘
                 │ [LAN Interface: wlan0 in AP mode]
                 │ [IP: 192.168.100.1]
                 │
     ┌───────────┴───────────┐
     │   WiFi Hotspot        │
     │   (hostapd + dnsmasq) │
     │   SSID: Mihomo-Gateway│
     │   DHCP: 192.168.100.x │
     └───────────┬───────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼───┐   ┌───▼───┐   ┌───▼───┐
│ Phone │   │Laptop │   │Tablet │
│ .100  │   │ .101  │   │ .102  │
└───────┘   └───────┘   └───────┘
  Client      Client      Client
  (Auto       (Auto       (Auto
   Proxy)      Proxy)      Proxy)
```

---

## 🔄 Process Flow

### 1. System Boot

```
systemd start
    │
    ├─► mihomo.service
    │   └─► Start Mihomo (proxy engine)
    │
    ├─► hostapd.service
    │   └─► Start WiFi AP
    │
    └─► dnsmasq.service
        └─► Start DHCP server
```

### 2. Client Connection

```
Client connects to hotspot
    │
    ├─► DHCP assigns IP (192.168.100.x)
    │
    ├─► DNS queries → redirected to Mihomo
    │
    ├─► HTTP/HTTPS traffic → transparent proxy
    │   │
    │   ├─► Rule matching
    │   │   ├─► DIRECT → bypass proxy
    │   │   ├─► PROXY → via proxy server
    │   │   └─► REJECT → blocked
    │   │
    │   └─► Proxy server → Internet
    │
    └─► NAT masquerade → Internet
```

### 3. Web UI Access

```
User opens browser → http://192.168.100.1/mihomo-ui
    │
    ├─► Apache serves index.php
    │
    ├─► JavaScript loads (main.js)
    │   ├─► Fetch stats via AJAX
    │   └─► Update UI real-time
    │
    └─► User action → api.php
        │
        ├─► Validate request
        ├─► Execute system command (via sudo)
        └─► Return JSON response
```

---

## 📦 Dependencies

### System Packages

```
Required:
├── bash                  # Shell scripting
├── systemd              # Service management
├── iptables             # Firewall & routing
├── iproute2 (ip)        # Network configuration
├── wireless-tools (iw)  # WiFi management
├── hostapd              # WiFi AP
├── dnsmasq              # DHCP & DNS
├── curl                 # HTTP requests
└── jq                   # JSON parsing

Web UI:
├── apache2 or nginx     # Web server
└── php (8.0+)
    ├── php-curl         # HTTP client
    ├── php-json         # JSON processing
    └── php-mbstring     # String handling
```

### External Components

```
Mihomo Binary:
├── Source: github.com/MetaCubeX/mihomo
├── Version: 1.18.0+
└── Architecture: amd64, arm64, etc.

Dashboards (Web UI):
├── Yacd
│   └── URL: yacd.haishan.me
└── MetaCubeX
    └── URL: metacubex.github.io/yacd
```

---

## 🎯 Feature Matrix

| Component               | Feature            | Status  | Location                     |
| ----------------------- | ------------------ | ------- | ---------------------------- |
| **Smart Setup**         | All-in-one setup   | ✅ v2.0 | scripts/smart-setup.sh       |
| **Interface Detection** | USB tethering      | ✅ v2.0 | scripts/detect-interfaces.sh |
| **Interface Detection** | Auto ethernet      | ✅ v2.0 | scripts/detect-interfaces.sh |
| **Interface Detection** | Auto WiFi          | ✅ v2.0 | scripts/detect-interfaces.sh |
| **WiFi Management**     | Channel scanning   | ✅ v2.0 | scripts/smart-channel.sh     |
| **WiFi Management**     | Auto-select        | ✅ v2.0 | scripts/smart-channel.sh     |
| **Hotspot**             | Auto-detection     | ✅ v2.0 | scripts/hotspot.sh           |
| **Hotspot**             | Web UI config      | ✅ v2.0 | webui/index.php + api.php    |
| **Routing**             | Auto-detection     | ✅ v2.0 | scripts/routing.sh           |
| **Routing**             | Transparent proxy  | ✅ v1.0 | scripts/routing.sh           |
| **Web UI**              | Dashboard          | ✅ v1.0 | webui/index.php              |
| **Web UI**              | External dashboard | ✅ v2.0 | webui/index.php              |
| **Monitoring**          | Real-time          | ✅ v1.0 | scripts/monitor.sh           |
| **Proxy**               | Rule-based         | ✅ v1.0 | config/config.yaml           |
| **DNS**                 | DoH + fake-ip      | ✅ v1.0 | config/config.yaml           |

---

## 🔮 Future Architecture (v3.0+)

```
Planned Enhancements:
├── Docker containerization
├── Multi-WAN load balancing
├── Advanced QoS engine
├── VPN server integration
├── Mesh network support
└── Mobile app (Android/iOS)
```

---

**Last Updated:** November 17, 2024  
**Version:** 2.0.0
