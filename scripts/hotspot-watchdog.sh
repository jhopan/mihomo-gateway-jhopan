#!/bin/bash
# Hotspot Watchdog - Auto-restart hotspot if down
# Keep hotspot always running

set -e

# Configuration
CHECK_INTERVAL=30  # Check every 30 seconds
MAX_RETRIES=3
LOG_FILE="/var/log/hotspot-watchdog.log"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    log "INFO: $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log "WARN: $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

# Check if hotspot is running
check_hotspot() {
    # Check hostapd
    if ! systemctl is-active --quiet hostapd; then
        return 1
    fi
    
    # Check dnsmasq
    if ! systemctl is-active --quiet dnsmasq; then
        return 1
    fi
    
    # Check wlan0 interface
    if ! ip addr show wlan0 | grep -q "192.168.1.1"; then
        return 1
    fi
    
    return 0
}

# Restart hotspot
restart_hotspot() {
    log_warn "Hotspot down! Attempting restart..."
    
    # Stop services
    systemctl stop hostapd 2>/dev/null || true
    systemctl stop dnsmasq 2>/dev/null || true
    
    # Wait a bit
    sleep 2
    
    # Configure interface
    ip addr flush dev wlan0 2>/dev/null || true
    ip addr add 192.168.1.1/24 dev wlan0 2>/dev/null || true
    ip link set wlan0 up 2>/dev/null || true
    
    # Start services
    systemctl start hostapd
    sleep 2
    systemctl start dnsmasq
    
    sleep 3
    
    # Verify
    if check_hotspot; then
        log_info "Hotspot restarted successfully!"
        return 0
    else
        log_error "Failed to restart hotspot"
        return 1
    fi
}

# Main watchdog loop
watchdog_loop() {
    log_info "Hotspot watchdog started (checking every ${CHECK_INTERVAL}s)"
    
    retry_count=0
    
    while true; do
        if check_hotspot; then
            # Hotspot is running fine
            if [ $retry_count -gt 0 ]; then
                log_info "Hotspot back online after $retry_count attempts"
                retry_count=0
            fi
        else
            # Hotspot is down
            retry_count=$((retry_count + 1))
            log_warn "Hotspot check failed (attempt $retry_count/$MAX_RETRIES)"
            
            if [ $retry_count -le $MAX_RETRIES ]; then
                restart_hotspot
            else
                log_error "Max retries reached. Manual intervention required!"
                # Send notification (optional)
                # You can add email/telegram notification here
                retry_count=0
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Handle signals
trap 'log_info "Watchdog stopped"; exit 0' SIGTERM SIGINT

# Main
case "${1:-start}" in
    start)
        watchdog_loop
        ;;
    check)
        if check_hotspot; then
            log_info "Hotspot is running"
            exit 0
        else
            log_error "Hotspot is down"
            exit 1
        fi
        ;;
    restart)
        restart_hotspot
        ;;
    *)
        echo "Usage: $0 {start|check|restart}"
        echo ""
        echo "Commands:"
        echo "  start   - Start watchdog daemon"
        echo "  check   - Check hotspot status"
        echo "  restart - Restart hotspot manually"
        exit 1
        ;;
esac
