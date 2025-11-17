#!/bin/bash
# Smart Routing and iptables setup script for Mihomo Gateway
# Auto-detects network interfaces

set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration (will be auto-detected if available)
WAN_INTERFACE=""      # Auto-detect internet connection
LAN_INTERFACE=""      # Auto-detect LAN interface
WIFI_INTERFACE=""     # Auto-detect WiFi interface
MIHOMO_PORT="7892"    # Mixed port (HTTP + SOCKS5)
MIHOMO_REDIR="7893"   # Redirect port for transparent proxy

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
            
            WAN_INTERFACE="$WAN_INTERFACE"
            WIFI_INTERFACE="$WIFI_INTERFACE"
            
            # Use first LAN interface if available
            if [ ${#LAN_INTERFACES[@]} -gt 0 ]; then
                LAN_INTERFACE="${LAN_INTERFACES[0]}"
            fi
            
            print_info "✓ Detected WAN: $WAN_INTERFACE ($WAN_TYPE)"
            [ -n "$LAN_INTERFACE" ] && print_info "✓ Detected LAN: $LAN_INTERFACE"
            [ -n "$WIFI_INTERFACE" ] && print_info "✓ Detected WiFi: $WIFI_INTERFACE"
            
            return 0
        fi
    else
        print_warn "Interface detection script not found"
    fi
    
    # Fallback to defaults if auto-detection fails
    if [ -z "$WAN_INTERFACE" ]; then
        print_warn "Using default interfaces (may not work!)"
        WAN_INTERFACE="eth0"
        LAN_INTERFACE="eth1"
        WIFI_INTERFACE="wlan0"
    fi
}

# Function to enable IP forwarding
enable_ip_forward() {
    print_info "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv6.conf.all.forwarding=1
    
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    
    if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    fi
}

# Function to setup NAT
setup_nat() {
    print_info "Setting up NAT..."
    
    # Flush existing rules
    iptables -t nat -F
    iptables -t mangle -F
    iptables -F
    iptables -X
    
    # Allow forwarding
    iptables -P FORWARD ACCEPT
    
    # NAT for internet sharing
    iptables -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE
    
    # Allow established connections
    iptables -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -j ACCEPT
    
    # WiFi interface (if exists)
    if ip link show $WIFI_INTERFACE &>/dev/null; then
        iptables -A FORWARD -i $WAN_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i $WIFI_INTERFACE -o $WAN_INTERFACE -j ACCEPT
    fi
    
    print_info "NAT configured"
}

# Function to setup transparent proxy
setup_transparent_proxy() {
    print_info "Setting up transparent proxy..."
    
    # Create new chain for Mihomo
    iptables -t nat -N MIHOMO
    
    # Bypass local addresses
    iptables -t nat -A MIHOMO -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A MIHOMO -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A MIHOMO -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A MIHOMO -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A MIHOMO -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A MIHOMO -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A MIHOMO -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A MIHOMO -d 240.0.0.0/4 -j RETURN
    
    # Redirect all TCP traffic to Mihomo
    iptables -t nat -A MIHOMO -p tcp -j REDIRECT --to-ports $MIHOMO_REDIR
    
    # Apply rules to local traffic
    iptables -t nat -A OUTPUT -p tcp -j MIHOMO
    
    # Apply rules to forwarded traffic (from LAN)
    iptables -t nat -A PREROUTING -i $LAN_INTERFACE -p tcp -j MIHOMO
    
    # WiFi interface (if exists)
    if ip link show $WIFI_INTERFACE &>/dev/null; then
        iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp -j MIHOMO
    fi
    
    print_info "Transparent proxy configured"
}

# Function to setup DNS redirect
setup_dns_redirect() {
    print_info "Setting up DNS redirect..."
    
    # Redirect DNS queries to Mihomo DNS (port 5353)
    iptables -t nat -A PREROUTING -i $LAN_INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 5353
    
    # WiFi interface (if exists)
    if ip link show $WIFI_INTERFACE &>/dev/null; then
        iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 5353
    fi
    
    print_info "DNS redirect configured"
}

# Function to save iptables rules
save_rules() {
    print_info "Saving iptables rules..."
    
    # Install iptables-persistent if not installed
    if ! command -v iptables-save &> /dev/null; then
        apt-get install -y iptables-persistent
    fi
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    
    print_info "Rules saved to /etc/iptables/rules.v4"
}

# Function to display current rules
show_rules() {
    print_info "Current iptables rules:"
    echo ""
    echo "=== NAT Table ==="
    iptables -t nat -L -n -v
    echo ""
    echo "=== Filter Table ==="
    iptables -L -n -v
}

# Function to clear all rules
clear_rules() {
    print_warn "Clearing all iptables rules..."
    
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -F
    iptables -X
    
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    print_info "All rules cleared"
}

# Function to setup everything
setup_all() {
    print_info "Starting full routing setup..."
    echo ""
    
    # Auto-detect interfaces first
    auto_detect_interfaces
    
    enable_ip_forward
    setup_nat
    setup_transparent_proxy
    setup_dns_redirect
    save_rules
    
    echo ""
    print_info "Routing setup completed!"
    echo ""
    echo "Configuration:"
    echo "  WAN Interface: $WAN_INTERFACE"
    echo "  LAN Interface: $LAN_INTERFACE"
    echo "  WiFi Interface: $WIFI_INTERFACE"
    echo "  Mihomo Mixed Port: $MIHOMO_PORT"
    echo "  Mihomo Redir Port: $MIHOMO_REDIR"
    echo ""
    echo "All traffic from LAN/WiFi will be routed through Mihomo."
    echo ""
}

# Main script
case "${1:-setup}" in
    setup)
        setup_all
        ;;
    nat-only)
        enable_ip_forward
        setup_nat
        save_rules
        ;;
    transparent)
        setup_transparent_proxy
        save_rules
        ;;
    dns)
        setup_dns_redirect
        save_rules
        ;;
    show)
        show_rules
        ;;
    clear)
        clear_rules
        ;;
    save)
        save_rules
        ;;
    *)
        echo "Usage: $0 {setup|nat-only|transparent|dns|show|clear|save}"
        echo ""
        echo "Commands:"
        echo "  setup       - Full setup (NAT + Transparent Proxy + DNS)"
        echo "  nat-only    - Setup NAT only (basic internet sharing)"
        echo "  transparent - Setup transparent proxy rules only"
        echo "  dns         - Setup DNS redirect only"
        echo "  show        - Show current iptables rules"
        echo "  clear       - Clear all iptables rules"
        echo "  save        - Save current rules"
        echo ""
        echo "Edit the script to change interface names:"
        echo "  WAN_INTERFACE: $WAN_INTERFACE"
        echo "  LAN_INTERFACE: $LAN_INTERFACE"
        echo "  WIFI_INTERFACE: $WIFI_INTERFACE"
        exit 1
        ;;
esac
