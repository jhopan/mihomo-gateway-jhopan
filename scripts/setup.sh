#!/bin/bash
# Mihomo Installation Script
# Run as root: sudo bash setup.sh

set -e

echo "======================================"
echo "Mihomo Gateway Installation Script"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        MIHOMO_ARCH="amd64"
        ;;
    aarch64|arm64)
        MIHOMO_ARCH="arm64"
        ;;
    armv7l)
        MIHOMO_ARCH="armv7"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH (mihomo: $MIHOMO_ARCH)"
echo ""

# Step 1: Install dependencies
echo "[1/9] Installing dependencies..."
apt update
apt install -y wget curl tar gzip apache2 php php-curl php-json php-mbstring \
    iptables iproute2 net-tools hostapd dnsmasq

# Enable Apache mod_rewrite
a2enmod rewrite
systemctl restart apache2

echo "✓ Dependencies installed"
echo ""

# Step 2: Download Mihomo
echo "[2/9] Downloading Mihomo..."
MIHOMO_VERSION="v1.18.0"
MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-${MIHOMO_ARCH}-${MIHOMO_VERSION}.gz"

mkdir -p /opt/mihomo
cd /opt/mihomo

if [ -f "mihomo" ]; then
    echo "Backing up existing mihomo binary..."
    mv mihomo mihomo.backup
fi

wget -O mihomo.gz "$MIHOMO_URL"
gunzip mihomo.gz
chmod +x mihomo

echo "✓ Mihomo downloaded"
echo ""

# Step 3: Setup directories
echo "[3/9] Setting up directories..."
mkdir -p /etc/mihomo
mkdir -p /etc/mihomo/proxies
mkdir -p /etc/mihomo/rules
mkdir -p /var/log/mihomo
mkdir -p /var/www/html/mihomo-ui

echo "✓ Directories created"
echo ""

# Step 4: Copy configuration files
echo "[4/9] Copying configuration files..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/config/config.yaml" ]; then
    cp "$PROJECT_DIR/config/config.yaml" /etc/mihomo/
fi

if [ -d "$PROJECT_DIR/config/proxies" ]; then
    cp -r "$PROJECT_DIR/config/proxies/"* /etc/mihomo/proxies/ 2>/dev/null || true
fi

if [ -d "$PROJECT_DIR/config/rules" ]; then
    cp -r "$PROJECT_DIR/config/rules/"* /etc/mihomo/rules/ 2>/dev/null || true
fi

# Generate random secret for API
SECRET=$(openssl rand -hex 16)
sed -i "s/your-secret-key-change-this/$SECRET/g" /etc/mihomo/config.yaml

echo "✓ Configuration files copied"
echo "✓ API Secret generated: $SECRET"
echo ""

# Step 5: Create systemd service
echo "[5/9] Creating systemd service..."
cat > /etc/systemd/system/mihomo.service << 'EOF'
[Unit]
Description=Mihomo Proxy Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/mihomo
ExecStart=/opt/mihomo/mihomo -d /etc/mihomo -f /etc/mihomo/config.yaml
Restart=on-failure
RestartSec=10s
StandardOutput=append:/var/log/mihomo/mihomo.log
StandardError=append:/var/log/mihomo/mihomo.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mihomo

echo "✓ Systemd service created"
echo ""

# Step 6: Setup Web UI
echo "[6/9] Setting up Web UI..."
if [ -d "$PROJECT_DIR/webui" ]; then
    cp -r "$PROJECT_DIR/webui/"* /var/www/html/mihomo-ui/
    chown -R www-data:www-data /var/www/html/mihomo-ui/
    chmod -R 755 /var/www/html/mihomo-ui/
fi

echo "✓ Web UI installed"
echo ""

# Step 7: Configure sudoers for www-data
echo "[7/9] Configuring permissions..."
if ! grep -q "www-data ALL=(ALL) NOPASSWD:" /etc/sudoers; then
    echo "www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/sbin/iptables, /usr/sbin/ip, /usr/bin/hostapd, /usr/sbin/dnsmasq" >> /etc/sudoers
fi

echo "✓ Permissions configured"
echo ""

# Step 8: Enable IP forwarding
echo "[8/9] Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

echo "✓ IP forwarding enabled"
echo ""

# Step 9: Start Mihomo service
echo "[9/9] Starting Mihomo service..."
systemctl start mihomo
sleep 3

if systemctl is-active --quiet mihomo; then
    echo "✓ Mihomo service started successfully"
else
    echo "✗ Mihomo service failed to start"
    echo "Check logs: journalctl -u mihomo -n 50"
    exit 1
fi

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Mihomo Status:"
systemctl status mihomo --no-pager | head -n 5
echo ""
echo "Configuration:"
echo "  - Config dir: /etc/mihomo"
echo "  - Binary: /opt/mihomo/mihomo"
echo "  - Log: /var/log/mihomo/mihomo.log"
echo ""
echo "Proxy Ports:"
echo "  - HTTP: 7890"
echo "  - SOCKS5: 7891"
echo "  - Mixed: 7892"
echo "  - External Controller: 9090"
echo ""
echo "API Access:"
echo "  - URL: http://$(hostname -I | awk '{print $1}'):9090"
echo "  - Secret: $SECRET"
echo ""
echo "Web UI:"
echo "  - URL: http://$(hostname -I | awk '{print $1}'):80/mihomo-ui"
echo "  - Default user: admin"
echo "  - Default pass: admin123"
echo ""
echo "Next steps:"
echo "  1. Edit /etc/mihomo/config.yaml to add your proxies"
echo "  2. Add proxy providers to /etc/mihomo/proxies/"
echo "  3. Restart service: sudo systemctl restart mihomo"
echo "  4. Access Web UI and change default password"
echo "  5. Configure hotspot if needed"
echo ""
echo "Useful commands:"
echo "  - Status: sudo systemctl status mihomo"
echo "  - Restart: sudo systemctl restart mihomo"
echo "  - Logs: sudo tail -f /var/log/mihomo/mihomo.log"
echo "  - Test: curl -x http://127.0.0.1:7890 https://www.google.com"
echo ""
