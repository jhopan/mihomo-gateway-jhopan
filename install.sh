#!/bin/bash
# Quick Installation Script for Mihomo Gateway
# Run: curl -fsSL https://raw.githubusercontent.com/jhopan/mihomo-gateway-jhopan/main/install.sh | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    echo -e "${BLUE}==>${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (sudo)"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   Mihomo Gateway Installation Script      ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   Version: 2.1.1                           ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Install dependencies
print_step "Step 1/7: Installing dependencies..."
apt update
apt install -y wget git curl unzip hostapd dnsmasq iptables iw speedtest-cli

# Step 2: Download Mihomo
print_step "Step 2/7: Downloading Mihomo..."
if [ ! -f "/usr/local/bin/mihomo" ]; then
    wget https://github.com/MetaCubeX/mihomo/releases/download/v1.19.16/mihomo-linux-amd64-compatible-v1.19.16.gz -O /tmp/mihomo.gz
    gunzip /tmp/mihomo.gz
    mv /tmp/mihomo /usr/local/bin/mihomo
    chmod +x /usr/local/bin/mihomo
    print_info "Mihomo installed: $(mihomo -v)"
else
    print_info "Mihomo already installed: $(mihomo -v)"
fi

# Step 3: Clone repository
print_step "Step 3/7: Cloning repository..."
if [ ! -d "/opt/mihomo-gateway" ]; then
    cd /opt
    git clone https://github.com/jhopan/mihomo-gateway-jhopan.git mihomo-gateway
    cd mihomo-gateway
else
    print_info "Repository already exists, pulling latest changes..."
    cd /opt/mihomo-gateway
    git pull
fi

# Step 4: Setup configuration
print_step "Step 4/7: Setting up configuration..."
mkdir -p /etc/mihomo
cp -r config/* /etc/mihomo/

print_warn "IMPORTANT: Edit /etc/mihomo/config.yaml to add your proxy servers!"
print_warn "           Also edit /etc/mihomo/proxy_providers/custom.yaml"

# Step 5: Setup Mihomo service
print_step "Step 5/7: Setting up Mihomo service..."
mkdir -p /var/log/mihomo
cp scripts/mihomo.service /etc/systemd/system/
systemctl daemon-reload

# Step 6: Setup routing
print_step "Step 6/7: Setting up routing..."
bash scripts/routing-enhanced.sh redirect

# Step 7: Setup hotspot
print_step "Step 7/7: Setting up hotspot..."
bash scripts/hotspot.sh setup

# Setup additional features
print_step "Setting up additional features..."

# Hotspot watchdog
cp scripts/hotspot-watchdog.service /etc/systemd/system/
chmod +x scripts/hotspot-watchdog.sh
systemctl daemon-reload
systemctl enable hotspot-watchdog

# Make monitoring scripts executable
chmod +x scripts/client-monitor.sh
chmod +x scripts/speedtest-api.sh
chmod +x scripts/smart-channel.sh

print_info "Installation completed!"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}              Next Steps                       ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo "1. Edit configuration:"
echo "   sudo nano /etc/mihomo/config.yaml"
echo "   sudo nano /etc/mihomo/proxy_providers/custom.yaml"
echo ""
echo "2. Start services:"
echo "   sudo systemctl start mihomo"
echo "   sudo systemctl start hotspot-watchdog"
echo "   sudo bash /opt/mihomo-gateway/scripts/hotspot.sh start"
echo ""
echo "3. Enable services on boot:"
echo "   sudo systemctl enable mihomo"
echo "   sudo systemctl enable hotspot-watchdog"
echo ""
echo "4. Check status:"
echo "   sudo systemctl status mihomo"
echo "   sudo systemctl status hotspot-watchdog"
echo "   sudo bash /opt/mihomo-gateway/scripts/hotspot.sh status"
echo ""
echo "5. Access Web UI:"
echo "   http://192.168.1.1:9090"
echo "   (Secret: mihomo-gateway-2024)"
echo ""
echo -e "${GREEN}Installation successful!${NC}"
echo ""
print_warn "Don't forget to edit the config files before starting services!"
