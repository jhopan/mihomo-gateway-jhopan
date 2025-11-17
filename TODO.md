# TODO - Mihomo Gateway Development

## ✅ Completed (v2.0.0)

### Core Features

- [x] USB tethering auto-detection (Android/iPhone)
- [x] Smart interface detection (USB > Ethernet > WiFi)
- [x] Smart WiFi channel selection
- [x] Web UI hotspot configuration (SSID, password, channel)
- [x] External dashboard integration (Yacd, MetaCubeX)
- [x] One-command smart setup script
- [x] Auto-detect routing & iptables
- [x] Real-time monitoring script
- [x] Complete documentation

### Scripts

- [x] detect-interfaces.sh - Interface auto-detection
- [x] smart-channel.sh - WiFi channel management
- [x] smart-setup.sh - All-in-one setup
- [x] Enhanced hotspot.sh with auto-detection
- [x] Enhanced routing.sh with auto-detection

### Web UI

- [x] Hotspot configuration form
- [x] External dashboard page (iframe)
- [x] Save hotspot config via API
- [x] Dashboard selector (Yacd/MetaCubeX)
- [x] Open dashboard in new tab

### Documentation

- [x] QUICK_START.md - Complete quick start guide
- [x] Updated README.md with smart features
- [x] Updated COMMANDS.md with new scripts
- [x] CHANGELOG.md - Version history

---

## 🚀 Priority (v2.1.0)

### High Priority

#### Bandwidth Management

- [ ] Per-client bandwidth limiting
  - [ ] Web UI interface for limits
  - [ ] tc (traffic control) integration
  - [ ] Real-time limit adjustment
  - [ ] Upload/download separate limits

#### Security Features

- [ ] MAC address filtering

  - [ ] Web UI MAC whitelist/blacklist
  - [ ] Auto-block unknown devices option
  - [ ] Temporary access codes

- [ ] Client isolation
  - [ ] Option to isolate hotspot clients
  - [ ] AP isolation in hostapd

#### QoS (Quality of Service)

- [ ] Priority queuing
  - [ ] Gaming traffic priority
  - [ ] Streaming traffic priority
  - [ ] Bulk download de-prioritization
- [ ] DPI (Deep Packet Inspection) integration

### Medium Priority

#### Web UI Enhancements

- [ ] Dark mode toggle
- [ ] Dashboard customization
- [ ] Multiple language support (EN/ID)
- [ ] Mobile-responsive improvements
- [ ] Real-time notifications

#### Monitoring

- [ ] Client traffic history
- [ ] Per-client statistics
- [ ] Export statistics to CSV/JSON
- [ ] Bandwidth usage alerts
- [ ] Email/Telegram notifications

#### Backup & Restore

- [ ] One-click config backup
- [ ] Scheduled backups
- [ ] Cloud backup support (optional)
- [ ] Easy restore from backup

---

## 🎯 Planned (v2.2.0)

### 5GHz WiFi Support

- [ ] Detect 5GHz capability
- [ ] Dual-band support (2.4GHz + 5GHz)
- [ ] Channel selection for 5GHz (36, 40, 44, 48, etc.)
- [ ] Band steering options

### Advanced Hotspot

- [ ] Multiple SSID support
- [ ] Guest network isolation
- [ ] Captive portal
- [ ] Voucher system
- [ ] Time-based access control

### Traffic Management

- [ ] Advanced traffic shaping
- [ ] Per-application QoS
- [ ] Gaming mode (low latency)
- [ ] Video streaming optimization

### VPN Features

- [ ] VPN passthrough support
- [ ] L2TP/IPSec support
- [ ] OpenVPN integration
- [ ] WireGuard support

---

## 🔮 Future (v3.0.0+)

### Docker & Containers

- [ ] Dockerized deployment
- [ ] Docker Compose support
- [ ] Container orchestration
- [ ] Kubernetes support

### Multi-WAN

- [ ] Load balancing across multiple WANs
- [ ] Failover automation
- [ ] WAN health check
- [ ] Policy-based routing per client

### Advanced Features

- [ ] Mesh network support
- [ ] SD-WAN capabilities
- [ ] Zero-trust networking
- [ ] AI-powered traffic optimization

### Integration

- [ ] Home Assistant integration
- [ ] Prometheus metrics export
- [ ] Grafana dashboards
- [ ] API for third-party apps

### Mobile App

- [ ] Android app for control
- [ ] iOS app for control
- [ ] Push notifications
- [ ] Remote management

---

## 🐛 Known Issues

### To Fix

- [ ] Channel scan timeout on some hardware
  - Workaround: Use manual channel selection
- [ ] DHCP lease file permissions

  - Workaround: `sudo chmod 644 /var/lib/misc/dnsmasq.leases`

- [ ] Web UI session timeout
  - TODO: Implement longer session duration

### To Investigate

- [ ] Performance on low-end hardware (< 2GB RAM)
- [ ] Compatibility with very old WiFi cards
- [ ] USB tethering stability on some Android models

---

## 🧪 Testing Needed

### Hardware Testing

- [ ] Test on various Debian versions (10, 11, 12)
- [ ] Test on Ubuntu (20.04, 22.04, 24.04)
- [ ] Test on Raspberry Pi 4/5
- [ ] Test with different WiFi adapters
- [ ] Test with USB Ethernet adapters

### USB Tethering Testing

- [ ] Android 10, 11, 12, 13, 14
- [ ] iOS 15, 16, 17
- [ ] Various phone brands (Samsung, Xiaomi, Oppo, iPhone)
- [ ] USB-C to USB-A adapters
- [ ] USB hubs

### Network Testing

- [ ] Multiple clients (10, 20, 50+)
- [ ] High bandwidth usage (torrents, 4K streaming)
- [ ] Gaming latency
- [ ] VoIP quality
- [ ] Long-term stability (24h, 7d, 30d uptime)

---

## 📚 Documentation Improvements

### Tutorials Needed

- [ ] Video tutorial (YouTube)
- [ ] Step-by-step screenshots
- [ ] Common scenarios guide
- [ ] Troubleshooting flowchart

### Translations

- [ ] Indonesian translation (full docs)
- [ ] English refinement
- [ ] Simplified Chinese (optional)

### API Documentation

- [ ] REST API reference
- [ ] Webhook documentation
- [ ] Integration examples

---

## 🎨 UI/UX Improvements

### Web UI

- [ ] Modern CSS framework (Bootstrap 5 or Tailwind)
- [ ] Better mobile experience
- [ ] Touch-friendly controls
- [ ] Drag-and-drop config
- [ ] Visual network topology

### CLI

- [ ] Interactive TUI (using `dialog` or `whiptail`)
- [ ] Better error messages
- [ ] Progress bars for long operations
- [ ] Colored output consistently

---

## 🔧 Code Improvements

### Refactoring

- [ ] Modularize scripts (common functions library)
- [ ] Error handling standardization
- [ ] Logging framework
- [ ] Config file validation

### Performance

- [ ] Optimize interface detection
- [ ] Reduce boot time
- [ ] Memory usage optimization
- [ ] Faster channel scanning

### Security

- [ ] Input sanitization review
- [ ] API rate limiting
- [ ] CSRF protection in Web UI
- [ ] Secure password storage

---

## 💡 Feature Requests (Community)

_Add community feature requests here_

---

## 🤝 Contributions Welcome

Want to contribute? Pick any TODO item and:

1. Fork the repository
2. Create feature branch
3. Implement feature
4. Test thoroughly
5. Update documentation
6. Submit pull request

**Priority areas for contributions:**

- Testing on different hardware
- Translations
- UI/UX improvements
- Performance optimization
- Bug fixes

---

## 📅 Release Schedule

- **v2.0.0** - ✅ Released (Smart Features)
- **v2.1.0** - Target: Q1 2025 (Bandwidth & Security)
- **v2.2.0** - Target: Q2 2025 (5GHz & Advanced)
- **v3.0.0** - Target: Q4 2025 (Docker & Multi-WAN)

---

**Last Updated:** November 17, 2024
**Maintainer:** [Your Name/Team]
