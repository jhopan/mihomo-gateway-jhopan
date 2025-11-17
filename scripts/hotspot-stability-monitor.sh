#!/bin/bash
# Hotspot Stability Monitor
# Auto-fix disconnection issues and restart services if needed

LOG_FILE="/var/log/hotspot-stability.log"
CHECK_INTERVAL=30  # Check every 30 seconds
MAX_RESTARTS=3
RESTART_COUNT=0
LAST_RESTART_TIME=0

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if hostapd is running but not responding
check_hostapd_health() {
    if systemctl is-active --quiet hostapd; then
        # Check if hostapd process is actually working
        if ! hostapd_cli status &>/dev/null; then
            log_message "WARNING: hostapd running but not responding"
            return 1
        fi
        return 0
    else
        log_message "ERROR: hostapd service stopped"
        return 1
    fi
}

# Check if dnsmasq is serving DHCP
check_dnsmasq_health() {
    if systemctl is-active --quiet dnsmasq; then
        # Check if dnsmasq is listening on port 67 (DHCP)
        if ! netstat -ln | grep -q ":67 "; then
            log_message "WARNING: dnsmasq running but not listening on DHCP port"
            return 1
        fi
        return 0
    else
        log_message "ERROR: dnsmasq service stopped"
        return 1
    fi
}

# Check WiFi interface status
check_wifi_interface() {
    local WIFI_INTERFACE=$(cat /etc/hostapd/hostapd.conf | grep "^interface=" | cut -d= -f2)
    
    if [ -z "$WIFI_INTERFACE" ]; then
        log_message "ERROR: Cannot determine WiFi interface"
        return 1
    fi
    
    # Check if interface is UP
    if ! ip link show "$WIFI_INTERFACE" | grep -q "state UP"; then
        log_message "WARNING: WiFi interface $WIFI_INTERFACE is DOWN"
        ip link set "$WIFI_INTERFACE" up
        sleep 2
    fi
    
    # Check if interface has IP
    if ! ip addr show "$WIFI_INTERFACE" | grep -q "inet "; then
        log_message "WARNING: WiFi interface has no IP address"
        return 1
    fi
    
    # Disable power management (again, in case it was re-enabled)
    iw dev "$WIFI_INTERFACE" set power_save off 2>/dev/null
    iwconfig "$WIFI_INTERFACE" power off 2>/dev/null
    
    return 0
}

# Check for stuck clients (connected but no traffic)
check_client_activity() {
    local WIFI_INTERFACE=$(cat /etc/hostapd/hostapd.conf | grep "^interface=" | cut -d= -f2)
    local CLIENT_COUNT=$(iw dev "$WIFI_INTERFACE" station dump 2>/dev/null | grep -c "^Station")
    
    if [ "$CLIENT_COUNT" -gt 0 ]; then
        log_message "INFO: $CLIENT_COUNT client(s) connected"
        
        # Check for inactive clients (no traffic for 5 minutes)
        iw dev "$WIFI_INTERFACE" station dump 2>/dev/null | grep -A 5 "^Station" | while read line; do
            if echo "$line" | grep -q "inactive time"; then
                local INACTIVE_TIME=$(echo "$line" | grep -oP '\d+')
                if [ "$INACTIVE_TIME" -gt 300000 ]; then  # 5 minutes in ms
                    local MAC=$(echo "$PREV_LINE" | awk '{print $2}')
                    log_message "WARNING: Client $MAC inactive for ${INACTIVE_TIME}ms, disconnecting..."
                    iw dev "$WIFI_INTERFACE" station del "$MAC" 2>/dev/null
                fi
            fi
            PREV_LINE="$line"
        done
    fi
}

# Restart hotspot services
restart_hotspot() {
    local current_time=$(date +%s)
    local time_since_last=$((current_time - LAST_RESTART_TIME))
    
    # Prevent restart loops (minimum 5 minutes between restarts)
    if [ "$time_since_last" -lt 300 ]; then
        RESTART_COUNT=$((RESTART_COUNT + 1))
        if [ "$RESTART_COUNT" -ge "$MAX_RESTARTS" ]; then
            log_message "ERROR: Too many restarts in short time, waiting 10 minutes..."
            sleep 600
            RESTART_COUNT=0
        fi
    else
        RESTART_COUNT=0
    fi
    
    log_message "INFO: Restarting hotspot services..."
    LAST_RESTART_TIME=$(date +%s)
    
    # Stop services
    systemctl stop hostapd
    systemctl stop dnsmasq
    sleep 2
    
    # Restart services
    systemctl start hostapd
    sleep 1
    systemctl start dnsmasq
    sleep 2
    
    if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
        log_message "INFO: Hotspot services restarted successfully"
        return 0
    else
        log_message "ERROR: Failed to restart hotspot services"
        return 1
    fi
}

# Main monitoring loop
log_message "=== Hotspot Stability Monitor Started ==="

while true; do
    ISSUES=0
    
    # Check all health indicators
    if ! check_wifi_interface; then
        ISSUES=$((ISSUES + 1))
    fi
    
    if ! check_hostapd_health; then
        ISSUES=$((ISSUES + 1))
    fi
    
    if ! check_dnsmasq_health; then
        ISSUES=$((ISSUES + 1))
    fi
    
    # Check client activity
    check_client_activity
    
    # If multiple issues detected, restart services
    if [ "$ISSUES" -ge 2 ]; then
        log_message "WARNING: Multiple issues detected ($ISSUES), restarting hotspot..."
        restart_hotspot
    elif [ "$ISSUES" -eq 1 ]; then
        log_message "WARNING: Minor issue detected, monitoring..."
    fi
    
    sleep "$CHECK_INTERVAL"
done
