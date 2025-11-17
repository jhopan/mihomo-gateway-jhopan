#!/bin/bash
# Smart Hotspot Management Script for Mihomo Gateway
# Auto-detects interfaces and selects best WiFi channel

set -e

# Default Configuration (can be overridden)
WIFI_INTERFACE=""           # Auto-detect
INTERNET_INTERFACE=""       # Auto-detect  
SSID="Mihomo-Gateway"       # Hotspot SSID
PASSWORD="mihomo2024"       # Hotspot password (min 8 chars)
CHANNEL="auto"              # WiFi channel (auto-select best, fallback to 11)
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
            
            if [ -n "$WIFI_INTERFACE" ] && [ -n "$INTERNET_INTERFACE" ]; then
                print_info "✓ Auto-detected WiFi: $WIFI_INTERFACE"
                print_info "✓ Auto-detected Internet: $INTERNET_INTERFACE ($WAN_TYPE)"
                return 0
            fi
        fi
    fi
    
    # Fallback: manual detection if script failed
    print_warn "Using fallback detection..."
    
    # Detect WiFi interface
    for iface in wlp2s0 wlan0 wlp3s0 wlp1s0; do
        if ip link show "$iface" &>/dev/null; then
            WIFI_INTERFACE="$iface"
            print_info "✓ Found WiFi: $WIFI_INTERFACE"
            break
        fi
    done
    
    # Detect Internet interface (priority: USB > Ethernet > Others)
    # 1. Try USB tethering (enx*, usb*)
    for iface in $(ip link show | grep -oP '(?<=: )enx[0-9a-z]+(?=:)'); do
        if ip addr show "$iface" 2>/dev/null | grep -q "inet "; then
            INTERNET_INTERFACE="$iface"
            print_info "✓ Found USB Tethering: $INTERNET_INTERFACE"
            return 0
        fi
    done
    
    # 2. Try ethernet
    for iface in eth0 enp0s3 eno1; do
        if ip link show "$iface" &>/dev/null && ip addr show "$iface" | grep -q "inet "; then
            INTERNET_INTERFACE="$iface"
            print_info "✓ Found Ethernet: $INTERNET_INTERFACE"
            return 0
        fi
    done
    
    # 3. Use any UP interface with IP (except WiFi, lo, docker, tailscale)
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v "^lo\|^docker\|^veth\|^tailscale\|^$WIFI_INTERFACE"); do
        if ip addr show "$iface" 2>/dev/null | grep -q "inet " && ip link show "$iface" | grep -q "state UP"; then
            INTERNET_INTERFACE="$iface"
            print_info "✓ Found Active Interface: $INTERNET_INTERFACE"
            return 0
        fi
    done
    
    print_error "Could not detect internet interface!"
    return 1
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
                print_warn "Channel auto-selection failed, using channel 11"
                CHANNEL="11"
            fi
        else
            print_warn "Channel selection script not found, using channel 11"
            CHANNEL="11"
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
    
    # Disable power management with full paths
    if [ -x /usr/sbin/iw ]; then
        /usr/sbin/iw dev $WIFI_INTERFACE set power_save off 2>/dev/null || true
    elif [ -x /sbin/iw ]; then
        /sbin/iw dev $WIFI_INTERFACE set power_save off 2>/dev/null || true
    fi
    if [ -x /sbin/iwconfig ]; then
        /sbin/iwconfig $WIFI_INTERFACE power off 2>/dev/null || true
    fi
    
    # Skip HT capabilities - causes "Hardware does not support configured channel" error
    # Most WiFi cards don't properly support HT40 in AP mode
    local HT_CAPS=""
    print_info "Using basic 802.11g/n (HT40 disabled for compatibility)"
    
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

# Stability improvements - Optimized for ath10k and old laptops
beacon_int=100
dtim_period=2
max_num_sta=10

# Timeouts - Optimized (600 = 10 minutes, proven stable)
ap_max_inactivity=600
disassoc_low_ack=0
skip_inactivity_poll=1

# Rekey intervals - Long intervals for stability
wpa_group_rekey=86400
wpa_ptk_rekey=600

# Control interface for monitoring
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# AP isolation OFF (allow client-to-client)
ap_isolate=0

# Key index workaround for compatibility
eapol_key_index_workaround=1

# Disable client power saving detection
wmm_ac_bk_cwmin=4
wmm_ac_bk_cwmax=10
wmm_ac_bk_aifs=7
wmm_ac_bk_txop_limit=0
wmm_ac_bk_acm=0
wmm_ac_be_aifs=3
wmm_ac_be_cwmin=4
wmm_ac_be_cwmax=10
wmm_ac_be_txop_limit=0
wmm_ac_be_acm=0
wmm_ac_vi_aifs=2
wmm_ac_vi_cwmin=3
wmm_ac_vi_cwmax=4
wmm_ac_vi_txop_limit=94
wmm_ac_vi_acm=0
wmm_ac_vo_aifs=2
wmm_ac_vo_cwmin=2
wmm_ac_vo_cwmax=3
wmm_ac_vo_txop_limit=47
wmm_ac_vo_acm=0

# AP isolation OFF (allow client-to-client)
ap_isolate=0
EOF

    # Add HT capabilities only if supported
    if [ -n "$HT_CAPS" ]; then
        echo "ht_capab=$HT_CAPS" >> /etc/hostapd/hostapd.conf
        print_info "HT capabilities enabled: $HT_CAPS"
    else
        print_warn "HT capabilities detection skipped (basic mode)"
    fi

    # Point hostapd to config file
    sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd
    
    # Verify config syntax
    if ! hostapd -t /etc/hostapd/hostapd.conf 2>/dev/null; then
        print_warn "Config test failed, using minimal config..."
        # Fallback to minimal working config
        cat > /etc/hostapd/hostapd.conf << EOF
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
country_code=ID
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ap_max_inactivity=0
disassoc_low_ack=0
skip_inactivity_poll=1
ap_isolate=0
EOF
    fi
    
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

# DHCP configuration with longer lease time
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,24h
dhcp-option=3,$IP_ADDRESS
dhcp-option=6,$IP_ADDRESS

# Prevent IP conflicts
dhcp-authoritative
dhcp-rapid-commit

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

# Cache settings for stability
cache-size=1000
dhcp-lease-max=100

# Prevent stale entries
dhcp-leasefile=/var/lib/misc/dnsmasq.leases
EOF

    print_info "dnsmasq configured"
}

# Configure network interface
setup_interface() {
    print_info "Configuring network interface..."
    
    # Stop services if running
    systemctl stop hostapd 2>/dev/null || true
    systemctl stop dnsmasq 2>/dev/null || true
    
    # Wait a bit
    sleep 1
    
    # Configure static IP
    ip addr flush dev $WIFI_INTERFACE 2>/dev/null || true
    ip link set $WIFI_INTERFACE down 2>/dev/null || true
    sleep 1
    ip link set $WIFI_INTERFACE up 2>/dev/null || true
    sleep 1
    ip addr add ${IP_ADDRESS}/24 dev $WIFI_INTERFACE 2>/dev/null || true
    
    print_info "Interface configured with IP: $IP_ADDRESS"
}

# Setup iptables for hotspot
setup_iptables() {
    print_info "Configuring iptables for hotspot..."
    
    # Use full path for iptables
    local IPTABLES="/usr/sbin/iptables"
    
    # Verify interfaces are set
    if [ -z "$WIFI_INTERFACE" ] || [ -z "$INTERNET_INTERFACE" ]; then
        print_error "Interfaces not properly detected!"
        print_error "WIFI: $WIFI_INTERFACE | INTERNET: $INTERNET_INTERFACE"
        return 1
    fi
    
    print_info "Setting up NAT: $WIFI_INTERFACE → $INTERNET_INTERFACE"
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
    
    # Clear existing rules for this interface
    $IPTABLES -D FORWARD -i "$WIFI_INTERFACE" -o "$INTERNET_INTERFACE" -j ACCEPT 2>/dev/null || true
    $IPTABLES -D FORWARD -i "$INTERNET_INTERFACE" -o "$WIFI_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    $IPTABLES -t nat -D POSTROUTING -o "$INTERNET_INTERFACE" -j MASQUERADE 2>/dev/null || true
    
    # Add new rules with proper quoting
    $IPTABLES -A FORWARD -i "$WIFI_INTERFACE" -o "$INTERNET_INTERFACE" -j ACCEPT
    $IPTABLES -A FORWARD -i "$INTERNET_INTERFACE" -o "$WIFI_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
    $IPTABLES -t nat -A POSTROUTING -o "$INTERNET_INTERFACE" -j MASQUERADE
    
    # Verify rules added
    if $IPTABLES -t nat -L POSTROUTING 2>/dev/null | grep -q MASQUERADE; then
        print_info "✓ iptables NAT configured successfully"
    else
        print_warn "iptables rules may not be applied correctly"
    fi
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
    
    # Bring WiFi interface UP if DOWN
    if ip link show $WIFI_INTERFACE | grep -q "state DOWN"; then
        print_info "Bringing WiFi interface UP..."
        ip link set $WIFI_INTERFACE up
        sleep 1
    fi
    
    # Disable power management to prevent disconnects (use full paths)
    print_info "Disabling power management..."
    if [ -x /usr/sbin/iw ]; then
        /usr/sbin/iw dev $WIFI_INTERFACE set power_save off 2>/dev/null || true
    elif [ -x /sbin/iw ]; then
        /sbin/iw dev $WIFI_INTERFACE set power_save off 2>/dev/null || true
    fi
    if [ -x /sbin/iwconfig ]; then
        /sbin/iwconfig $WIFI_INTERFACE power off 2>/dev/null || true
    fi
    
    # Set WiFi to always on (no sleep)
    ethtool -s $WIFI_INTERFACE wol d 2>/dev/null || true
    
    # Auto-select channel
    auto_select_channel
    
    # Setup everything
    setup_hostapd
    setup_dnsmasq
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
    
    systemctl stop hostapd 2>/dev/null || true
    systemctl stop dnsmasq 2>/dev/null || true
    
    # Auto-detect interface if not set
    if [ -z "$WIFI_INTERFACE" ]; then
        auto_detect_interfaces 2>/dev/null || true
    fi
    
    # Remove IP address if interface exists
    if [ -n "$WIFI_INTERFACE" ] && ip link show $WIFI_INTERFACE &>/dev/null; then
        ip addr flush dev $WIFI_INTERFACE 2>/dev/null || true
    fi
    
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
