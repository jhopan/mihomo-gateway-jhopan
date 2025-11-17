# Changelog - Mihomo Gateway

## [2.0.0] - Smart Features Update - 2024-11-17

### 🎯 Major Features Added

#### Auto-Detection System

- ✅ **USB Tethering Auto-Detection**

  - Automatic detection of USB tethering from Android/iPhone
  - Support for multiple USB interface types (usb0, rndis0, usb1, ncm0, etc.)
  - Internet connectivity validation
  - Priority-based selection

- ✅ **Smart Interface Detection**

  - Multi-interface detection (USB, Ethernet, WiFi)
  - Priority system: USB > Ethernet > WiFi
  - Automatic interface selection
  - State saved to `/tmp/mihomo-interfaces.conf`

- ✅ **Smart WiFi Channel Selection**
  - Auto-scan available channels
  - Detect hardware limitations
  - Avoid banned/disabled channels
  - Channel congestion analysis
  - Automatic selection of best channel
  - Manual channel validation

#### Web UI Enhancements

- ✅ **Hotspot Configuration via Web UI**

  - SSID configuration
  - Password management (min 8 chars)
  - WiFi channel selection (Auto/Manual)
  - Form validation
  - Real-time config updates

- ✅ **External Dashboard Integration**
  - Yacd Dashboard embedded
  - MetaCubeX Dashboard embedded
  - Iframe integration
  - Open in new tab option
  - Full proxy & rules control

#### Automation Scripts

- ✅ **smart-setup.sh** - All-in-one setup script

  - 5-step automated setup
  - Interactive prompts
  - Colored output
  - Comprehensive summary
  - Real-time monitoring option

- ✅ **detect-interfaces.sh** - Interface detection

  - Detect USB tethering
  - Detect Ethernet
  - Detect WiFi WAN
  - Internet connectivity check
  - Save configuration

- ✅ **smart-channel.sh** - WiFi channel management
  - Channel info & capabilities
  - Auto-scan nearby networks
  - Channel analysis & scoring
  - Auto-select best channel
  - Manual channel validation

### 🔧 Script Enhancements

#### hotspot.sh

- Added `auto_detect_interfaces()` function
- Added `auto_select_channel()` function
- Integrated with detect-interfaces.sh
- Integrated with smart-channel.sh
- No more manual interface configuration needed

#### routing.sh

- Added `auto_detect_interfaces()` at script start
- Automatic WAN interface detection
- Dynamic NAT configuration
- No more manual interface editing needed

#### webui/api.php

- Added `configure_hotspot` endpoint
- Added `get_hotspot_config` endpoint
- Added `restart_hotspot` endpoint
- Form validation & sanitization

#### webui/index.php

- Added Hotspot Configuration form
- Added External Dashboard page
- Improved navigation
- Better UI/UX

#### webui/assets/js/main.js

- Added `saveHotspotConfig()` function
- Added `loadExternalDashboard()` function
- Added `openDashboardNewTab()` function
- Form validation & AJAX handling

#### webui/assets/css/style.css

- Added dashboard styles
- Added form styles
- Added info-box styles
- Improved responsive design

### 📚 Documentation Updates

#### New Files

- **QUICK_START.md** - Complete quick start guide
  - USB tethering setup
  - Smart features usage
  - Web UI configuration
  - Troubleshooting

#### Updated Files

- **README.md**

  - Added smart features section
  - Updated installation guide
  - Added quick reference table
  - Updated troubleshooting

- **COMMANDS.md**
  - Added interface detection commands
  - Added smart channel commands
  - Added smart-setup.sh reference
  - Updated hotspot commands with Web UI notes

### 🐛 Bug Fixes

- Fixed channel selection on limited hardware
- Fixed interface detection edge cases
- Improved error handling in all scripts
- Better validation in Web UI forms

### 🎨 UI/UX Improvements

- Colored terminal output in scripts
- Interactive prompts in smart-setup.sh
- Better status messages
- Comprehensive summary displays
- Progress indicators

---

## [1.0.0] - Initial Release

### Features

- Mihomo (Clash Meta) core integration
- Basic Web UI dashboard
- Hotspot management
- Routing & iptables scripts
- Monitoring tools
- systemd service
- Basic documentation

### Components

- config.yaml - Mihomo configuration
- webui/ - Web dashboard
- scripts/ - Helper scripts
  - setup.sh
  - hotspot.sh
  - routing.sh
  - monitor.sh
  - mihomo.service

### Documentation

- README.md
- INSTALL_GUIDE.md
- COMMANDS.md
- COMPARISON.md

---

## Upgrade Path

### From 1.0.0 to 2.0.0

**Automatic (Recommended):**

```bash
cd mihomo-gateway
git pull
sudo bash scripts/smart-setup.sh
```

**Manual:**

1. Backup existing configs:

   ```bash
   sudo cp /etc/mihomo/config.yaml ~/config.yaml.backup
   sudo cp /etc/hostapd/hostapd.conf ~/hostapd.conf.backup
   ```

2. Copy new scripts:

   ```bash
   sudo cp scripts/detect-interfaces.sh /usr/local/bin/
   sudo cp scripts/smart-channel.sh /usr/local/bin/
   sudo cp scripts/smart-setup.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/{detect-interfaces,smart-channel,smart-setup}.sh
   ```

3. Update existing scripts:

   ```bash
   sudo cp scripts/hotspot.sh /usr/local/bin/
   sudo cp scripts/routing.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/{hotspot,routing}.sh
   ```

4. Update Web UI:

   ```bash
   sudo cp -r webui/* /var/www/html/mihomo-ui/
   sudo chown -R www-data:www-data /var/www/html/mihomo-ui/
   ```

5. Run smart setup:
   ```bash
   sudo bash /usr/local/bin/smart-setup.sh
   ```

---

## Future Plans

### Version 2.1.0 (Planned)

- [ ] Bandwidth limiting per client
- [ ] MAC filtering via Web UI
- [ ] QoS management
- [ ] VPN passthrough options
- [ ] Multiple SSID support

### Version 2.2.0 (Planned)

- [ ] 5GHz WiFi support
- [ ] Advanced traffic shaping
- [ ] Client statistics & history
- [ ] Automated backup/restore
- [ ] Mobile app for control

### Version 3.0.0 (Planned)

- [ ] Docker support
- [ ] Multi-WAN load balancing
- [ ] Failover automation
- [ ] Advanced firewall rules
- [ ] VPN server integration

---

## Contributing

Contributions welcome! Please:

1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

---

## License

MIT License - See LICENSE file for details

---

**Happy Gateway-ing! 🚀**
