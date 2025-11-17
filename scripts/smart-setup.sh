#!/bin/bash
# Mihomo Gateway - Smart All-in-One Setup Script
# Otomatis detect interface, setup routing, dan start hotspot

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║           🚀 MIHOMO GATEWAY - SMART SETUP 🚀                  ║"
    echo "║                                                                ║"
    echo "║              OpenWRT-like Gateway for Debian                   ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root: sudo bash $0"
    exit 1
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

print_banner

# Step 1: Detect Interfaces
print_step "STEP 1/5: Detecting Network Interfaces"

if [ -f "detect-interfaces.sh" ]; then
    bash detect-interfaces.sh detect
    
    if [ ! -f "/tmp/mihomo-interfaces.conf" ]; then
        print_error "Interface detection failed!"
        exit 1
    fi
    
    source /tmp/mihomo-interfaces.conf
    
    print_info "✓ Detected WAN: $WAN_INTERFACE ($WAN_TYPE)"
    [ -n "$WIFI_INTERFACE" ] && print_info "✓ Detected WiFi: $WIFI_INTERFACE"
else
    print_warn "detect-interfaces.sh not found, skipping auto-detection"
fi

sleep 2

# Step 2: Setup Routing & iptables
print_step "STEP 2/5: Configuring Routing & iptables"

if [ -f "routing.sh" ]; then
    print_info "Setting up NAT and transparent proxy..."
    bash routing.sh setup
    
    if [ $? -eq 0 ]; then
        print_info "✓ Routing configured successfully"
    else
        print_warn "Routing setup had issues, but continuing..."
    fi
else
    print_warn "routing.sh not found, skipping"
fi

sleep 2

# Step 3: Check Mihomo Status
print_step "STEP 3/5: Checking Mihomo Service"

if systemctl is-active --quiet mihomo; then
    print_info "✓ Mihomo is running"
    
    # Show version
    VERSION=$(curl -s http://127.0.0.1:9090/version 2>/dev/null | grep -oP '(?<="version":")[^"]+' || echo "Unknown")
    print_info "Version: $VERSION"
else
    print_warn "Mihomo is not running!"
    print_info "Starting Mihomo..."
    
    systemctl start mihomo
    sleep 3
    
    if systemctl is-active --quiet mihomo; then
        print_info "✓ Mihomo started successfully"
    else
        print_error "Failed to start Mihomo!"
        print_info "Check logs: journalctl -u mihomo -n 50"
        exit 1
    fi
fi

sleep 2

# Step 4: Setup Hotspot (if WiFi available)
print_step "STEP 4/5: Setting Up WiFi Hotspot"

if [ -n "$WIFI_INTERFACE" ]; then
    print_info "WiFi interface available: $WIFI_INTERFACE"
    
    read -p "Do you want to setup/start hotspot? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "hotspot.sh" ]; then
            # Check if already configured
            if [ ! -f "/etc/hostapd/hostapd.conf" ]; then
                print_info "Setting up hotspot for the first time..."
                bash hotspot.sh setup
            fi
            
            print_info "Starting hotspot..."
            bash hotspot.sh start
            
            if [ $? -eq 0 ]; then
                print_info "✓ Hotspot started successfully"
            else
                print_warn "Failed to start hotspot"
            fi
        else
            print_warn "hotspot.sh not found"
        fi
    else
        print_info "Skipping hotspot setup"
    fi
else
    print_warn "No WiFi interface available for hotspot"
fi

sleep 2

# Step 5: Summary & Next Steps
print_step "STEP 5/5: Setup Complete!"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}                    ${CYAN}SETUP SUCCESSFUL!${NC}                      ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get IP addresses
if [ -n "$WAN_INTERFACE" ]; then
    WAN_IP=$(ip -4 addr show "$WAN_INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    echo -e "${CYAN}Internet Connection:${NC}"
    echo "  Interface: $WAN_INTERFACE ($WAN_TYPE)"
    echo "  IP: $WAN_IP"
    echo ""
fi

if [ -n "$WIFI_INTERFACE" ] && systemctl is-active --quiet hostapd; then
    SSID=$(grep "^ssid=" /etc/hostapd/hostapd.conf 2>/dev/null | cut -d'=' -f2)
    CHANNEL=$(grep "^channel=" /etc/hostapd/hostapd.conf 2>/dev/null | cut -d'=' -f2)
    
    echo -e "${CYAN}Hotspot Information:${NC}"
    echo "  SSID: $SSID"
    echo "  Channel: $CHANNEL"
    echo "  IP: 192.168.100.1"
    echo "  Password: Check /etc/hostapd/hostapd.conf"
    echo ""
fi

echo -e "${CYAN}Mihomo Proxy:${NC}"
echo "  HTTP Proxy: http://127.0.0.1:7890"
echo "  SOCKS5: socks5://127.0.0.1:7891"
echo "  Mixed Port: 7892"
echo "  API: http://127.0.0.1:9090"
echo ""

echo -e "${CYAN}Web Interface:${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "  Local: http://localhost/mihomo-ui"
echo "  Network: http://$SERVER_IP/mihomo-ui"
if [ -n "$WIFI_INTERFACE" ] && systemctl is-active --quiet hostapd; then
    echo "  Hotspot: http://192.168.100.1/mihomo-ui"
fi
echo ""
echo "  Default Login:"
echo "    Username: admin"
echo "    Password: admin123"
echo ""

echo -e "${CYAN}Useful Commands:${NC}"
echo "  • Check status: systemctl status mihomo"
echo "  • View logs: journalctl -u mihomo -f"
echo "  • Monitor: bash scripts/monitor.sh"
echo "  • Hotspot status: bash scripts/hotspot.sh status"
echo "  • Test internet: curl -x http://127.0.0.1:7890 https://google.com"
echo ""

echo -e "${CYAN}External Dashboards:${NC}"
echo "  • Yacd: https://yacd.haishan.me/?hostname=$SERVER_IP&port=9090"
echo "  • MetaCubeX: https://metacubex.github.io/yacd/?hostname=$SERVER_IP&port=9090"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "  1. Change default password in Web UI!"
echo "  2. Configure your proxies in /etc/mihomo/config.yaml"
echo "  3. Restart service after config changes: systemctl restart mihomo"
echo ""

echo -e "${GREEN}✨ Your Debian laptop is now a powerful gateway like OpenWRT!${NC}"
echo ""

# Optional: Start monitoring
read -p "Do you want to start real-time monitoring? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "monitor.sh" ]; then
        bash monitor.sh
    fi
fi
