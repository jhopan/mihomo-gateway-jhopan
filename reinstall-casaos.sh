#!/bin/bash

# Reinstall CasaOS dari awal
# Untuk kasus CasaOS yang corrupt atau gagal install

set -e

echo "========================================"
echo "  Reinstall CasaOS"
echo "========================================"
echo ""

# Step 1: Backup data (jika ada)
echo "[1/5] Backing up CasaOS data..."
if [ -d /var/lib/casaos ]; then
    sudo cp -r /var/lib/casaos /var/lib/casaos.backup.$(date +%Y%m%d-%H%M%S)
    echo "  - Data backed up"
fi

# Step 2: Stop dan remove semua CasaOS services
echo "[2/5] Stopping and removing CasaOS services..."
sudo systemctl stop casaos.service casaos-user-service.service casaos-message-bus.service || true
sudo systemctl disable casaos.service casaos-user-service.service casaos-message-bus.service || true

# Step 3: Remove CasaOS packages (jika ada)
echo "[3/5] Removing old CasaOS installation..."
if command -v apt &>/dev/null; then
    sudo apt remove --purge -y casaos casaos-gateway casaos-app-management casaos-local-storage casaos-user-service 2>/dev/null || true
    sudo apt autoremove -y
fi

# Clean up files
sudo rm -rf /usr/bin/casaos
sudo rm -rf /etc/casaos
sudo rm -rf /usr/lib/systemd/system/casaos*.service

# Step 4: Install CasaOS fresh
echo "[4/5] Installing CasaOS..."
echo ""
echo "  This will download and install CasaOS from official source..."
echo ""

# Download and run installer
curl -fsSL https://get.casaos.io | sudo bash

# Step 5: Verify installation
echo ""
echo "[5/5] Verifying installation..."
sleep 3

if systemctl is-active --quiet casaos.service; then
    echo "  ✓ CasaOS Main Service: Running"
else
    echo "  ✗ CasaOS Main Service: Failed"
fi

if systemctl is-active --quiet casaos-user-service.service; then
    echo "  ✓ CasaOS User Service: Running"
else
    echo "  ✗ CasaOS User Service: Failed"
fi

if systemctl is-active --quiet casaos-message-bus.service; then
    echo "  ✓ CasaOS Message Bus: Running"
else
    echo "  ✗ CasaOS Message Bus: Failed"
fi

echo ""
echo "========================================"
echo "  Installation Complete"
echo "========================================"
echo ""
echo "CasaOS should be available at:"
echo "  http://192.168.1.1:80 (or port displayed above)"
echo ""
echo "If there are still errors, check logs:"
echo "  sudo journalctl -u casaos.service -f"
echo ""
