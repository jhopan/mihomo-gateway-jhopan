#!/bin/bash

# Script untuk memperbaiki CasaOS yang gagal start
# Mengatasi configuration errors dan service failures

set -e

echo "========================================"
echo "  FIX CasaOS Services"
echo "========================================"
echo ""

# Step 1: Stop semua CasaOS services
echo "[1/6] Stopping all CasaOS services..."
sudo systemctl stop casaos.service || true
sudo systemctl stop casaos-user-service.service || true
sudo systemctl stop casaos-message-bus.service || true
sleep 2

# Step 2: Check dan fix CasaOS configuration
echo "[2/6] Checking CasaOS configuration..."

# Backup existing config if exists
if [ -f /etc/casaos/casaos.conf ]; then
    sudo cp /etc/casaos/casaos.conf /etc/casaos/casaos.conf.backup.$(date +%Y%m%d-%H%M%S)
    echo "  - Config backed up"
fi

# Reset CasaOS database if corrupted
if [ -f /var/lib/casaos/db/casaos.db ]; then
    echo "  - Checking database..."
    # Check if DB is readable
    if ! sudo sqlite3 /var/lib/casaos/db/casaos.db "SELECT 1;" &>/dev/null; then
        echo "  - Database corrupted, backing up and recreating..."
        sudo mv /var/lib/casaos/db/casaos.db /var/lib/casaos/db/casaos.db.corrupt.$(date +%Y%m%d-%H%M%S)
    fi
fi

# Step 3: Reset failed services
echo "[3/6] Resetting failed services..."
sudo systemctl reset-failed casaos.service || true
sudo systemctl reset-failed casaos-user-service.service || true
sudo systemctl reset-failed casaos-message-bus.service || true

# Step 4: Fix permissions
echo "[4/6] Fixing CasaOS permissions..."
sudo chown -R root:root /etc/casaos/ || true
sudo chmod -R 755 /etc/casaos/ || true
sudo chown -R casaos:casaos /var/lib/casaos/ || true
sudo chmod -R 755 /var/lib/casaos/ || true

# Step 5: Reinstall CasaOS if needed
echo "[5/6] Checking CasaOS installation..."
if ! command -v casaos &>/dev/null; then
    echo "  - CasaOS binary not found, reinstalling..."
    curl -fsSL https://get.casaos.io | sudo bash
else
    echo "  - CasaOS binary found: $(which casaos)"
fi

# Step 6: Start CasaOS services
echo "[6/6] Starting CasaOS services..."
sudo systemctl daemon-reload
sudo systemctl start casaos-message-bus.service
sleep 2
sudo systemctl start casaos-user-service.service
sleep 2
sudo systemctl start casaos.service
sleep 3

echo ""
echo "========================================"
echo "  Status Check"
echo "========================================"

# Check service status
echo ""
echo "CasaOS Message Bus:"
systemctl is-active casaos-message-bus.service && echo "  ✓ Running" || echo "  ✗ Failed"

echo "CasaOS User Service:"
systemctl is-active casaos-user-service.service && echo "  ✓ Running" || echo "  ✗ Failed"

echo "CasaOS Main Service:"
systemctl is-active casaos.service && echo "  ✓ Running" || echo "  ✗ Failed"

echo ""
echo "CasaOS Web UI should be available at:"
echo "  http://192.168.1.1:80"
echo ""

# Show recent logs if there are errors
if ! systemctl is-active --quiet casaos.service; then
    echo "========================================"
    echo "  Error Logs (last 10 lines)"
    echo "========================================"
    sudo journalctl -u casaos.service -n 10 --no-pager
    echo ""
    echo "To see full logs: sudo journalctl -u casaos.service -f"
fi

echo ""
echo "Done!"
