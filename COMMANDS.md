# Mihomo Gateway - Quick Commands Reference

## ⚡ Quick Start (NEW!)

```bash
# All-in-one smart setup (Recommended!)
sudo bash scripts/smart-setup.sh

# Detects: USB tethering, Ethernet, WiFi
# Configures: Routing, Mihomo, Hotspot
# Shows: All access URLs & info
```

---

## 🔍 Interface Detection (NEW!)

```bash
# Auto-detect all interfaces
sudo bash scripts/detect-interfaces.sh detect

# Show detection result
sudo bash scripts/detect-interfaces.sh show

# Check internet connection on interface
sudo bash scripts/detect-interfaces.sh check eth0

# Detect USB tethering specifically
sudo bash scripts/detect-interfaces.sh usb

# Detect Ethernet
sudo bash scripts/detect-interfaces.sh ethernet

# Detect WiFi WAN
sudo bash scripts/detect-interfaces.sh wifi-wan

# View saved config
cat /tmp/mihomo-interfaces.conf
```

---

## 📡 Smart WiFi Channel (NEW!)

```bash
# Get WiFi info & supported channels
sudo bash scripts/smart-channel.sh wlan0 info

# Auto-select best channel
sudo bash scripts/smart-channel.sh wlan0 auto

# Manual select channel (with validation)
sudo bash scripts/smart-channel.sh wlan0 select 6

# Scan nearby networks & analyze
sudo bash scripts/smart-channel.sh wlan0 scan
```

---

## 🚀 Service Management

```bash
# Start Mihomo
sudo systemctl start mihomo

# Stop Mihomo
sudo systemctl stop mihomo

# Restart Mihomo
sudo systemctl restart mihomo

# Check status
sudo systemctl status mihomo

# Enable auto-start on boot
sudo systemctl enable mihomo

# Disable auto-start
sudo systemctl disable mihomo

# Reload configuration (without restart)
sudo systemctl reload mihomo
```

## 📊 Monitoring

```bash
# Real-time monitoring
sudo bash scripts/monitor.sh

# Quick stats
sudo bash scripts/monitor.sh stats

# Test connectivity
sudo bash scripts/monitor.sh test

# View logs (real-time)
sudo tail -f /var/log/mihomo/mihomo.log

# View systemd logs
sudo journalctl -u mihomo -f

# Last 50 log lines
sudo journalctl -u mihomo -n 50
```

## 🌐 Proxy Testing

```bash
# Test HTTP proxy
curl -x http://127.0.0.1:7890 https://www.google.com

# Test SOCKS5 proxy
curl -x socks5://127.0.0.1:7891 https://www.google.com

# Check public IP through proxy
curl -x http://127.0.0.1:7890 https://api.ipify.org

# Test proxy with timing
curl -w "\nTime: %{time_total}s\n" -x http://127.0.0.1:7890 https://www.google.com
```

## 🔌 Mihomo API

```bash
# Get version
curl http://127.0.0.1:9090/version

# Get configs
curl http://127.0.0.1:9090/configs

# Get proxies
curl http://127.0.0.1:9090/proxies

# Get traffic
curl http://127.0.0.1:9090/traffic

# Get connections
curl http://127.0.0.1:9090/connections

# Get rules
curl http://127.0.0.1:9090/rules

# Switch proxy mode (rule/global/direct)
curl -X PATCH -H "Content-Type: application/json" \
  -d '{"mode":"rule"}' \
  http://127.0.0.1:9090/configs

# Select proxy in group
curl -X PUT -H "Content-Type: application/json" \
  -d '{"name":"proxy-name"}' \
  http://127.0.0.1:9090/proxies/GROUP-NAME
```

## 🔥 Routing & iptables

```bash
# Full routing setup with auto-detection (Recommended!)
sudo bash scripts/routing.sh setup
# Auto-detects: USB tethering, Ethernet, WiFi
# Configures: NAT, transparent proxy, DNS redirect

# NAT only (without transparent proxy)
sudo bash scripts/routing.sh nat-only

# Setup transparent proxy
sudo bash scripts/routing.sh transparent

# Setup DNS redirect
sudo bash scripts/routing.sh dns

# Show current rules
sudo bash scripts/routing.sh show

# Clear all rules
sudo bash scripts/routing.sh clear

# Save rules (persistent across reboot)
sudo bash scripts/routing.sh save

# View NAT table
sudo iptables -t nat -L -n -v

# View filter table
sudo iptables -L -n -v

# Check IP forwarding
sysctl net.ipv4.ip_forward
```

## 📡 Hotspot Management

```bash
# Setup hotspot with smart auto-detection
sudo bash scripts/hotspot.sh setup

# Start hotspot (uses auto-detected interface)
sudo bash scripts/hotspot.sh start

# Stop hotspot
sudo bash scripts/hotspot.sh stop

# Restart hotspot
sudo bash scripts/hotspot.sh restart

# Check status
sudo bash scripts/hotspot.sh status

# Show connected clients
sudo bash scripts/hotspot.sh clients

# Change SSID (also via Web UI!)
sudo bash scripts/hotspot.sh change-ssid "NewName"

# Change password (also via Web UI!)
sudo bash scripts/hotspot.sh change-password "newpass123"

# Check hostapd status
sudo systemctl status hostapd

# Check dnsmasq status
sudo systemctl status dnsmasq

# View DHCP leases
cat /var/lib/misc/dnsmasq.leases
```

### 🎛️ Hotspot via Web UI (Recommended!)

```
1. Login Web UI: http://192.168.100.1/mihomo-ui
2. Menu: Hotspot > Hotspot Configuration
3. Edit: SSID, Password, Channel
4. Click: Save Configuration
5. Restart hotspot if needed
```

## 🔧 Configuration

```bash
# Edit main config
sudo nano /etc/mihomo/config.yaml

# Edit custom proxies
sudo nano /etc/mihomo/proxies/custom.yaml

# Edit custom rules
sudo nano /etc/mihomo/rules/custom.yaml

# Validate config syntax
sudo /opt/mihomo/mihomo -t -d /etc/mihomo -f /etc/mihomo/config.yaml

# Backup config
sudo tar -czf ~/mihomo-backup-$(date +%Y%m%d).tar.gz /etc/mihomo/

# Restore config
sudo tar -xzf ~/mihomo-backup-20240101.tar.gz -C /
```

## 🌐 Network Interface

```bash
# Show all interfaces
ip addr show

# Show interface brief
ip -br addr show

# Show specific interface
ip addr show eth0

# Show routing table
ip route show

# Enable interface
sudo ip link set eth0 up

# Disable interface
sudo ip link set eth0 down

# Set static IP
sudo ip addr add 192.168.1.100/24 dev eth0

# Remove IP
sudo ip addr del 192.168.1.100/24 dev eth0

# Add route
sudo ip route add 192.168.2.0/24 via 192.168.1.1

# Show WiFi info
iw dev

# Scan WiFi
sudo iw dev wlan0 scan
```

## 📈 System Info

```bash
# Check IP forwarding
sysctl net.ipv4.ip_forward

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Check system uptime
uptime

# Check CPU usage
top

# Check memory usage
free -h

# Check disk usage
df -h

# Check network usage
iftop

# Check processes
ps aux | grep mihomo

# Check listening ports
sudo netstat -tulpn | grep mihomo
# atau
sudo ss -tulpn | grep mihomo
```

## 🔐 Security

```bash
# Change Web UI password
# Edit in web UI Settings page or modify login.php

# Generate random secret
openssl rand -hex 16

# Check open ports
sudo nmap localhost

# Check firewall status
sudo ufw status

# Enable firewall
sudo ufw enable

# Allow SSH
sudo ufw allow 22

# Allow HTTP
sudo ufw allow 80

# Allow HTTPS
sudo ufw allow 443

# Allow Mihomo API (careful!)
sudo ufw allow 9090
```

## 🔄 Updates

```bash
# Update Mihomo binary
cd /opt/mihomo
sudo wget https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-latest.gz
sudo mv mihomo mihomo.old
sudo gunzip mihomo-linux-amd64-latest.gz
sudo mv mihomo-linux-amd64-latest mihomo
sudo chmod +x mihomo
sudo systemctl restart mihomo

# Update system packages
sudo apt update
sudo apt upgrade -y

# Update proxy providers (via API)
curl -X PUT http://127.0.0.1:9090/providers/proxies/provider1

# Update rule providers
curl -X PUT http://127.0.0.1:9090/providers/rules/reject
```

## 🐛 Debugging

```bash
# Test config file
sudo /opt/mihomo/mihomo -t -d /etc/mihomo -f /etc/mihomo/config.yaml

# Run Mihomo in foreground (debug mode)
sudo /opt/mihomo/mihomo -d /etc/mihomo -f /etc/mihomo/config.yaml

# Check DNS resolution
nslookup google.com 127.0.0.1

# Check port is listening
sudo netstat -tulpn | grep 7890

# Test iptables redirect
sudo iptables -t nat -L MIHOMO -n -v

# Check TUN interface
ip tuntap show

# Trace route
traceroute -n google.com

# Packet capture
sudo tcpdump -i any port 7890 -n

# Check file permissions
ls -la /etc/mihomo/
ls -la /opt/mihomo/
```

## 📦 Backup & Restore

```bash
# Full backup
sudo tar -czf ~/mihomo-full-backup-$(date +%Y%m%d).tar.gz \
  /etc/mihomo/ \
  /var/www/html/mihomo-ui/ \
  /opt/mihomo/mihomo

# Config only backup
sudo cp /etc/mihomo/config.yaml ~/config.yaml.backup

# Database/cache backup (if needed)
sudo tar -czf ~/mihomo-cache-$(date +%Y%m%d).tar.gz /etc/mihomo/*.db

# Restore from backup
sudo tar -xzf ~/mihomo-full-backup-20240101.tar.gz -C /

# Restore config only
sudo cp ~/config.yaml.backup /etc/mihomo/config.yaml
sudo systemctl restart mihomo
```

## 🔍 Useful One-Liners

```bash
# Count active connections
curl -s http://127.0.0.1:9090/connections | grep -o '"id"' | wc -l

# Get current upload/download speed
curl -s http://127.0.0.1:9090/traffic | jq '.up, .down'

# List all proxy names
curl -s http://127.0.0.1:9090/proxies | jq 'keys[]'

# Get current mode
curl -s http://127.0.0.1:9090/configs | jq '.mode'

# Count total rules
curl -s http://127.0.0.1:9090/rules | jq 'length'

# Check if Mihomo is running
systemctl is-active mihomo && echo "Running" || echo "Stopped"

# Get Mihomo PID
pgrep -x mihomo

# Get Mihomo memory usage
ps aux | grep mihomo | grep -v grep | awk '{print $6}'

# Auto-restart if down
systemctl is-active mihomo || sudo systemctl restart mihomo

# Watch traffic in real-time
watch -n 1 'curl -s http://127.0.0.1:9090/traffic'

# Watch connections count
watch -n 2 'curl -s http://127.0.0.1:9090/connections | grep -o "\"id\"" | wc -l'
```

## 🚨 Emergency Commands

```bash
# Stop all services
sudo systemctl stop mihomo hostapd dnsmasq

# Clear all iptables rules
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Reset network interface
sudo ip link set eth0 down
sudo ip link set eth0 up
sudo dhclient eth0

# Restore from backup config
sudo cp /etc/mihomo/config.yaml.backup /etc/mihomo/config.yaml
sudo systemctl restart mihomo

# Kill Mihomo process
sudo killall mihomo

# Restart network service
sudo systemctl restart networking

# Full system restart
sudo reboot
```

## 📱 Web UI Access

```
Local: http://localhost/mihomo-ui
LAN: http://192.168.x.x/mihomo-ui
WiFi Hotspot: http://192.168.100.1/mihomo-ui

Default Login:
Username: admin
Password: admin123
```

## 🔗 Useful Paths

```
Mihomo Binary: /opt/mihomo/mihomo
Config Dir: /etc/mihomo/
Main Config: /etc/mihomo/config.yaml
Proxies: /etc/mihomo/proxies/
Rules: /etc/mihomo/rules/
Logs: /var/log/mihomo/mihomo.log
Web UI: /var/www/html/mihomo-ui/
Service File: /etc/systemd/system/mihomo.service
Scripts: ~/mihomo-gateway/scripts/
```

## 💡 Tips

1. Always backup config before making changes
2. Test config syntax before restarting service
3. Monitor logs when troubleshooting
4. Use API for automation
5. Keep Mihomo updated
6. Secure your API endpoint
7. Use strong passwords
8. Regular backups recommended

---

**Save this file for quick reference! 📌**
