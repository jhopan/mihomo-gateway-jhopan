#!/bin/bash

# USB Tethering Watchdog
# Monitor USB interface dan auto-fix jika ada masalah

LOG_FILE="/var/log/usb-watchdog.log"
CHECK_INTERVAL=30  # Check every 30 seconds

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_and_fix_usb() {
    # Detect USB interface
    USB_IF=$(ip link show | grep -oE 'enx[a-f0-9]+' | head -1)
    
    if [ -z "$USB_IF" ]; then
        log_message "WARNING: USB interface not found"
        return 1
    fi
    
    # Check if interface is UP
    if ! ip link show "$USB_IF" | grep -q "state UP"; then
        log_message "WARNING: USB interface $USB_IF is DOWN, bringing up..."
        sudo ip link set "$USB_IF" up
        sleep 2
    fi
    
    # Check if we have IP address
    USB_IP=$(ip -4 addr show "$USB_IF" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    
    if [ -z "$USB_IP" ]; then
        log_message "WARNING: No IP on $USB_IF, requesting DHCP..."
        sudo dhcpcd "$USB_IF" 2>&1 | tee -a "$LOG_FILE"
        sleep 3
        USB_IP=$(ip -4 addr show "$USB_IF" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    fi
    
    # Check internet connectivity
    if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        log_message "ERROR: No internet connectivity, attempting fix..."
        
        # Reset USB interface
        log_message "Resetting USB interface..."
        sudo ip link set "$USB_IF" down
        sleep 2
        sudo ip link set "$USB_IF" up
        sleep 3
        
        # Request DHCP
        log_message "Requesting DHCP..."
        sudo dhcpcd "$USB_IF" 2>&1 | tee -a "$LOG_FILE"
        sleep 3
        
        # Fix NAT routing
        log_message "Fixing NAT routing..."
        sudo iptables -t nat -F POSTROUTING
        sudo iptables -F FORWARD
        sudo iptables -t nat -A POSTROUTING -o "$USB_IF" -j MASQUERADE
        sudo iptables -A FORWARD -i wlp2s0 -o "$USB_IF" -j ACCEPT
        sudo iptables -A FORWARD -i "$USB_IF" -o wlp2s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
        
        # Test again
        if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
            log_message "SUCCESS: Internet connectivity restored!"
        else
            log_message "ERROR: Still no internet after fix attempt"
        fi
    fi
}

log_message "USB Watchdog started"

while true; do
    check_and_fix_usb
    sleep "$CHECK_INTERVAL"
done
