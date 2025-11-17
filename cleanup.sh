#!/bin/bash

echo "Cleaning up unnecessary files..."
echo ""

# Root directory cleanup
ROOT_CLEANUP=(
    "check-wifi-capabilities.sh"
    "test-speed-manual.sh"
    "CHANGELOG.md"
    "CHANGELOG_V2.1.md"
    "COMMANDS.md"
    "COMPARISON.md"
    "INSTALL_GUIDE.md"
    "PROJECT_SUMMARY.md"
    "QUICK_START.md"
    "STRUCTURE.md"
    "TODO.md"
    "ULTRA_QUICK.md"
    "UPGRADE_V2.1.md"
)

# Scripts directory cleanup
SCRIPT_CLEANUP=(
    "scripts/smart-channel.sh"
    "scripts/smart-setup.sh"
    "scripts/routing-enhanced.sh"
    "scripts/hotspot-stability-monitor.sh"
    "scripts/hotspot-stability-monitor.service"
)

REMOVED=0

echo "Removing root files..."
for file in "${ROOT_CLEANUP[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✅ Removed: $file"
        ((REMOVED++))
    fi
done

echo ""
echo "Removing unused scripts..."
for file in "${SCRIPT_CLEANUP[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✅ Removed: $file"
        ((REMOVED++))
    fi
done

echo ""
echo "================================================"
echo "Cleanup complete! Removed $REMOVED files."
echo "================================================"
echo ""
echo "📁 Essential files kept:"
echo ""
echo "Root:"
echo "  ✅ README.md          - Main documentation"
echo "  ✅ SETUP.md           - Complete setup guide"
echo "  ✅ LICENSE            - Project license"
echo "  ✅ install.sh         - Installation script"
echo "  ✅ diagnose.sh        - Troubleshooting tool"
echo ""
echo "Scripts:"
echo "  ✅ hotspot.sh         - Hotspot control (start/stop/restart)"
echo "  ✅ detect-interfaces.sh - Network detection"
echo "  ✅ client-monitor.sh  - Monitor connected clients"
echo "  ✅ monitor.sh         - System monitoring"
echo "  ✅ routing.sh         - NAT & routing setup"
echo "  ✅ setup.sh           - Initial setup"
echo "  ✅ speedtest-api.sh   - Speed test API"
echo "  ✅ hotspot-watchdog.* - Auto-restart on failure"
echo "  ✅ mihomo.service     - Mihomo systemd service"
echo ""
echo "Config:"
echo "  ✅ config/            - Mihomo configurations"
echo "  ✅ webui/             - Web control panel"
echo ""
