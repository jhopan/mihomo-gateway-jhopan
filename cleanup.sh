#!/bin/bash

echo "Cleaning up debugging scripts..."
echo ""

# List of debugging scripts to remove
DEBUG_SCRIPTS=(
    "apply-stable-config.sh"
    "auto-test-channels.sh"
    "final-working-solution.sh"
    "fix-ath10k.sh"
    "fix-auth-timeout.sh"
    "fix-conflict.sh"
    "fix-hostapd-final.sh"
    "fix-hostapd-stable.sh"
    "fix-hotspot-emergency.sh"
    "fix-mac-randomization.sh"
    "fix-old-laptop-wifi.sh"
    "fix-open-network.sh"
    "try-minimal-wpa.sh"
    "ultimate-fix.sh"
    "use-working-config.sh"
    "test-all-channels.sh"
    "test-channels-with-speed.sh"
)

REMOVED=0
for script in "${DEBUG_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "✅ Removed: $script"
        ((REMOVED++))
    fi
done

echo ""
echo "Cleanup complete! Removed $REMOVED debug scripts."
echo ""
echo "Keeping only essential scripts:"
ls -lh *.sh 2>/dev/null | awk '{print "  ✅", $9}'
echo ""
