#!/bin/bash

# Setup USB Watchdog Service
# Auto-monitor dan fix USB tethering issues

set -e

echo "========================================"
echo "  Setup USB Watchdog Service"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root (sudo bash setup-usb-watchdog.sh)"
    exit 1
fi

# Make script executable
echo "[1/4] Making watchdog script executable..."
chmod +x /opt/mihomo-gateway/scripts/usb-watchdog.sh

# Copy systemd service file
echo "[2/4] Installing systemd service..."
cp /opt/mihomo-gateway/systemd/usb-watchdog.service /etc/systemd/system/

# Reload systemd and enable service
echo "[3/4] Enabling service..."
systemctl daemon-reload
systemctl enable usb-watchdog.service

# Start service
echo "[4/4] Starting USB Watchdog service..."
systemctl start usb-watchdog.service

echo ""
echo "========================================"
echo "  USB Watchdog Service Status"
echo "========================================"
systemctl status usb-watchdog.service --no-pager

echo ""
echo "Done! USB Watchdog is now monitoring your connection."
echo ""
echo "Useful commands:"
echo "  sudo systemctl status usb-watchdog    # Check status"
echo "  sudo systemctl stop usb-watchdog      # Stop service"
echo "  sudo systemctl restart usb-watchdog   # Restart service"
echo "  sudo journalctl -u usb-watchdog -f    # View live logs"
echo "  sudo tail -f /var/log/usb-watchdog.log # View watchdog log"
echo ""
