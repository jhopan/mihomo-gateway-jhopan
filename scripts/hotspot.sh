#!/bin/bash
# Smart Hotspot Management Script for Mihomo Gateway
# Auto-detects interfaces and selects best WiFi channel

set -e

# Default Configuration (can be overridden)
WIFI_INTERFACE=""           # Auto-detect
INTERNET_INTERFACE=""       # Auto-detect  
SSID="Mihomo-Gateway"       # Hotspot SSID
PASSWORD="mihomo2024"       # Hotspot password (min 8 chars)
CHANNEL="auto"              # WiFi channel (auto-select best)
IP_ADDRESS="192.168.1.1"    # Hotspot IP (easy to remember!)
DHCP_RANGE_START="192.168.1.10"
DHCP_RANGE_END="192.168.1.100"
SUBNET="192.168.1.0/24"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Auto-detect network interfaces
auto_detect_interfaces() {
    print_info "Auto-detecting network interfaces..."
    
    # Run interface detection script
    if [ -f "$SCRIPT_DIR/detect-interfaces.sh" ]; then
        bash "$SCRIPT_DIR/detect-interfaces.sh" detect > /dev/null
        
        # Load detected interfaces
        if [ -f "/tmp/mihomo-interfaces.conf" ]; then
            source /tmp/mihomo-interfaces.conf
            
            INTERNET_INTERFACE="$WAN_INTERFACE"
            
            if [ -n "$WIFI_INTERFACE" ]; then
                print_info "✓ Auto-detected WiFi: $WIFI_INTERFACE"
                print_info "✓ Auto-detected Internet: $INTERNET_INTERFACE ($WAN_TYPE)"
                return 0
            else
                print_error "No available WiFi interface found for hotspot!"
                return 1
            fi
        fi
    else
        print_warn "Interface detection script not found, using defaults"
        WIFI_INTERFACE="wlan0"
        INTERNET_INTERFACE="eth0"
    fi
}

# Auto-select best WiFi channel
auto_select_channel() {
    if [ "$CHANNEL" = "auto" ] || [ -z "$CHANNEL" ]; then
        print_info "Auto-selecting best WiFi channel..."
        
        if [ -f "$SCRIPT_DIR/smart-channel.sh" ]; then
            CHANNEL=$(bash "$SCRIPT_DIR/smart-channel.sh" "$WIFI_INTERFACE" auto 2>/dev/null | tail -1)
            
            if [ -n "$CHANNEL" ] && [[ "$CHANNEL" =~ ^[0-9]+$ ]]; then
                print_info "✓ Selected channel: $CHANNEL"
            else
                print_warn "Channel auto-selection failed, using channel 6"
                CHANNEL="6"
            fi
        else
            print_warn "Channel selection script not found, using channel 6"
            CHANNEL="6"
        fi
    else
        # Verify channel is supported
        if [ -f "$SCRIPT_DIR/smart-channel.sh" ]; then
            if bash "$SCRIPT_DIR/smart-channel.sh" "$WIFI_INTERFACE" test "$CHANNEL" &>/dev/null; then
                print_info "✓ Channel $CHANNEL is supported"
            else
                print_warn "Channel $CHANNEL not supported, auto-selecting..."
                CHANNEL=$(bash "$SCRIPT_DIR/smart-channel.sh" "$WIFI_INTERFACE" auto 2>/dev/null | tail -1)
                print_info "✓ Using channel: $CHANNEL"
            fi
        fi
    fi
}

# Install required packages
install_packages() {
    print_info "Installing required packages..."
    apt-get update
    apt-get install -y hostapd dnsmasq iptables iw
    print_info "Packages installed"
}

# Setup hostapd configuration
setup_hostapd() {
    print_info "Configuring hostapd..."
    
    cat > /etc/hostapd/hostapd.conf << EOF
# Interface and driver
interface=$WIFI_INTERFACE
driver=nl80211

# SSID and network settings
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0

# WPA2 security
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP

# Country code (adjust to your country)
country_code=ID
ieee80211n=1
ieee80211d=1
EOF

    # Point hostapd to config file
    sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd
    
    print_info "hostapd configured"
}

# Setup dnsmasq configuration
setup_dnsmasq() {
    print_info "Configuring dnsmasq..."
    
    # Backup original config
    if [ -f /etc/dnsmasq.conf ]; then
        cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
    fi
    
    cat > /etc/dnsmasq.conf << EOF
# Interface configuration
interface=$WIFI_INTERFACE
bind-interfaces

# DHCP configuration
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,12h
dhcp-option=3,$IP_ADDRESS
dhcp-option=6,$IP_ADDRESS

# DNS configuration
server=8.8.8.8
server=8.8.4.4
server=1.1.1.1

# Domain
domain=local
local=/local/

# Logging
log-queries
log-dhcp

# Cache
cache-size=1000
EOF

    print_info "dnsmasq configured"
}

# Configure network interface
setup_interface() {
    print_info "Configuring network interface..."
    
    # Stop services if running
    systemctl stop hostapd 2>/dev/null || true
    systemctl stop dnsmasq 2>/dev/null || true
    
    # Configure static IP
    ip addr flush dev $WIFI_INTERFACE
    ip addr add $IP_ADDRESS/24 dev $WIFI_INTERFACE
    ip link set $WIFI_INTERFACE up
    
    print_info "Interface configured with IP: $IP_ADDRESS"
}

# Setup iptables for hotspot
setup_iptables() {
    print_info "Configuring iptables for hotspot..."
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1
    
    # Clear existing rules for this interface
    iptables -D FORWARD -i $WIFI_INTERFACE -o $INTERNET_INTERFACE -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i $INTERNET_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o $INTERNET_INTERFACE -j MASQUERADE 2>/dev/null || true
    
    # Add new rules
    iptables -A FORWARD -i $WIFI_INTERFACE -o $INTERNET_INTERFACE -j ACCEPT
    iptables -A FORWARD -i $INTERNET_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -t nat -A POSTROUTING -o $INTERNET_INTERFACE -j MASQUERADE
    
    # Save rules
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4
    fi
    
    print_info "iptables configured"
}

# Start hotspot
start_hotspot() {
    print_info "Starting hotspot..."
    
    # Auto-detect interfaces if not set
    if [ -z "$WIFI_INTERFACE" ] || [ -z "$INTERNET_INTERFACE" ]; then
        auto_detect_interfaces || exit 1
    fi
    
    # Check if WiFi interface exists
    if ! ip link show $WIFI_INTERFACE &>/dev/null; then
        print_error "WiFi interface $WIFI_INTERFACE not found!"
        exit 1
    fi
    
    # Auto-select channel
    auto_select_channel
    
    # Setup everything
    setup_interface
    setup_iptables
    
    # Start services
    systemctl unmask hostapd
    systemctl start hostapd
    systemctl start dnsmasq
    
    sleep 2
    
    # Check status
    if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
        print_info "Hotspot started successfully!"
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════${NC}"
        echo -e "${GREEN}Hotspot Details:${NC}"
        echo -e "${BLUE}═══════════════════════════════════════${NC}"
        echo -e "  SSID: ${YELLOW}$SSID${NC}"
        echo -e "  Password: ${YELLOW}$PASSWORD${NC}"
        echo -e "  Channel: ${YELLOW}$CHANNEL${NC}"
        echo -e "  IP Address: ${YELLOW}$IP_ADDRESS${NC}"
        echo -e "  DHCP Range: ${YELLOW}$DHCP_RANGE_START - $DHCP_RANGE_END${NC}"
        echo -e "${BLUE}═══════════════════════════════════════${NC}"
    else
        print_error "Failed to start hotspot!"
        echo "Check logs:"
        echo "  hostapd: sudo journalctl -u hostapd -n 20"
        echo "  dnsmasq: sudo journalctl -u dnsmasq -n 20"
        exit 1
    fi
}

# Stop hotspot
stop_hotspot() {
    print_info "Stopping hotspot..."
    
    systemctl stop hostapd
    systemctl stop dnsmasq
    
    # Remove IP address
    ip addr flush dev $WIFI_INTERFACE
    
    print_info "Hotspot stopped"
}

# Get hotspot status
status_hotspot() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Hotspot Status${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    # Check hostapd
    if systemctl is-active --quiet hostapd; then
        echo -e "  hostapd: ${GREEN}Running${NC}"
    else
        echo -e "  hostapd: ${RED}Stopped${NC}"
    fi
    
    # Check dnsmasq
    if systemctl is-active --quiet dnsmasq; then
        echo -e "  dnsmasq: ${GREEN}Running${NC}"
    else
        echo -e "  dnsmasq: ${RED}Stopped${NC}"
    fi
    
    echo ""
    
    # Show connected clients
    if systemctl is-active --quiet hostapd; then
        echo -e "${GREEN}Connected Clients:${NC}"
        if [ -f /var/lib/misc/dnsmasq.leases ]; then
            awk '{print "  - " $3 " (" $2 ") - " $4}' /var/lib/misc/dnsmasq.leases
        else
            echo "  No clients connected"
        fi
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
}

# Show connected clients
show_clients() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Connected Clients${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    if [ -f /var/lib/misc/dnsmasq.leases ]; then
        printf "%-20s %-20s %-15s\n" "HOSTNAME" "MAC ADDRESS" "IP ADDRESS"
        echo "─────────────────────────────────────────────────────"
        awk '{printf "%-20s %-20s %-15s\n", $4, $2, $3}' /var/lib/misc/dnsmasq.leases
    else
        echo "No clients connected or dnsmasq not running"
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
}

# Setup (install and configure)
setup_all() {
    print_info "Setting up hotspot..."
    
    # Auto-detect interfaces
    auto_detect_interfaces || {
        print_warn "Could not auto-detect interfaces"
        print_info "Please manually set WIFI_INTERFACE and INTERNET_INTERFACE"
        return 1
    }
    
    # Auto-select channel
    auto_select_channel
    
    install_packages
    setup_hostapd
    setup_dnsmasq
    
    print_info "Setup completed!"
    echo ""
    echo "Configuration saved. You can now start the hotspot with:"
    echo "  sudo $0 start"
}

# Change SSID
change_ssid() {
    local new_ssid="$1"
    if [ -z "$new_ssid" ]; then
        read -p "Enter new SSID: " new_ssid
    fi
    
    sed -i "s/^ssid=.*/ssid=$new_ssid/" /etc/hostapd/hostapd.conf
    print_info "SSID changed to: $new_ssid"
    print_warn "Restart hotspot to apply changes"
}

# Change password
change_password() {
    local new_pass="$1"
    if [ -z "$new_pass" ]; then
        read -sp "Enter new password (min 8 chars): " new_pass
        echo ""
    fi
    
    if [ ${#new_pass} -lt 8 ]; then
        print_error "Password must be at least 8 characters"
        exit 1
    fi
    
    sed -i "s/^wpa_passphrase=.*/wpa_passphrase=$new_pass/" /etc/hostapd/hostapd.conf
    print_info "Password changed"
    print_warn "Restart hotspot to apply changes"
}

# Main script
check_root

case "${1:-help}" in
    setup)
        setup_all
        ;;
    start)
        start_hotspot
        ;;
    stop)
        stop_hotspot
        ;;
    restart)
        stop_hotspot
        sleep 2
        start_hotspot
        ;;
    status)
        status_hotspot
        ;;
    clients)
        show_clients
        ;;
    change-ssid)
        change_ssid "$2"
        ;;
    change-password)
        change_password "$2"
        ;;
    *)
        echo "Mihomo Gateway - Hotspot Management"
        echo ""
        echo "Usage: $0 {setup|start|stop|restart|status|clients|change-ssid|change-password}"
        echo ""
        echo "Commands:"
        echo "  setup            - Install and configure hotspot (first time)"
        echo "  start            - Start hotspot"
        echo "  stop             - Stop hotspot"
        echo "  restart          - Restart hotspot"
        echo "  status           - Show hotspot status"
        echo "  clients          - Show connected clients"
        echo "  change-ssid      - Change SSID"
        echo "  change-password  - Change password"
        echo ""
        echo "Examples:"
        echo "  $0 setup"
        echo "  $0 start"
        echo "  $0 change-ssid \"MyNewSSID\""
        echo "  $0 change-password \"newpassword123\""
        echo ""
        exit 1
        ;;
esac
