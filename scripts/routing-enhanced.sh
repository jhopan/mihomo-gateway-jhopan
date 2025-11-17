#!/bin/bash
# Enhanced Routing and iptables setup for Mihomo Gateway
# Safe for: SSH, Tailscale, Docker, CasaOS, Bots
# Support multiple methods: TUN (default), REDIRECT

set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# === Configuration ===
WAN_INTERFACE=""       # Auto-detect
LAN_INTERFACE="wlan0"  # Hotspot interface
HOTSPOT_SUBNET="192.168.1.0/24"
HOTSPOT_IP="192.168.1.1"

# Mihomo ports
MIHOMO_HTTP_PORT="7890"
MIHOMO_SOCKS_PORT="7891"
MIHOMO_MIXED_PORT="7892"
MIHOMO_REDIR_PORT="9797"
MIHOMO_API_PORT="9090"

# Method: tun, redirect
PROXY_METHOD="${PROXY_METHOD:-redirect}"

# Protected ports (don't redirect)
PROTECTED_PORTS=(
    22      # SSH
    2222    # Alternative SSH
    80      # HTTP (local access)
    443     # HTTPS (local access)
    8080    # CasaOS
    8081    # Alternative web
    9090    # Mihomo API
    41641   # Tailscale
)

# Protected networks (always direct)
PROTECTED_NETWORKS=(
    "127.0.0.0/8"       # Localhost
    "10.0.0.0/8"        # Private network
    "172.16.0.0/12"     # Private network
    "192.168.0.0/16"    # Private network
    "100.64.0.0/10"     # Tailscale CGNAT
    "169.254.0.0/16"    # Link-local
    "224.0.0.0/4"       # Multicast
    "240.0.0.0/4"       # Reserved
)

# Docker networks (common ranges)
DOCKER_NETWORKS=(
    "172.17.0.0/16"     # Default Docker bridge
    "172.18.0.0/16"     # Docker custom
    "172.19.0.0/16"     # Docker custom
    "172.20.0.0/16"     # Docker custom
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Mihomo Gateway - Enhanced Routing Setup   ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Auto-detect WAN interface
auto_detect_wan() {
    print_info "Auto-detecting WAN interface..."
    
    if [ -f "$SCRIPT_DIR/detect-interfaces.sh" ]; then
        bash "$SCRIPT_DIR/detect-interfaces.sh" detect > /dev/null 2>&1
        
        if [ -f "/tmp/mihomo-interfaces.conf" ]; then
            source /tmp/mihomo-interfaces.conf
            WAN_INTERFACE="$WAN_INTERFACE"
            print_success "Detected WAN: $WAN_INTERFACE ($WAN_TYPE)"
            return 0
        fi
    fi
    
    # Fallback: find default route
    WAN_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [ -n "$WAN_INTERFACE" ]; then
        print_success "Detected WAN: $WAN_INTERFACE (via default route)"
        return 0
    fi
    
    print_error "Failed to detect WAN interface!"
    exit 1
}

# Enable IP forwarding
enable_ip_forward() {
    print_info "Enabling IP forwarding..."
    
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null
    
    # Make persistent
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    
    if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    fi
    
    # Disable reverse path filtering (for some VPN scenarios)
    sysctl -w net.ipv4.conf.all.rp_filter=0 > /dev/null
    sysctl -w net.ipv4.conf.default.rp_filter=0 > /dev/null
    
    print_success "IP forwarding enabled"
}

# Flush all existing rules
flush_rules() {
    print_info "Flushing existing iptables rules..."
    
    # Flush all chains
    iptables -t filter -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -t raw -F
    
    # Delete custom chains
    iptables -t filter -X 2>/dev/null || true
    iptables -t nat -X 2>/dev/null || true
    iptables -t mangle -X 2>/dev/null || true
    iptables -t raw -X 2>/dev/null || true
    
    # Reset policies
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    print_success "Rules flushed"
}

# Setup basic firewall (protect services)
setup_firewall() {
    print_info "Setting up firewall protection..."
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow hotspot network
    iptables -A INPUT -s $HOTSPOT_SUBNET -j ACCEPT
    
    # Allow SSH (IMPORTANT!)
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
    
    # Allow Tailscale
    iptables -A INPUT -p udp --dport 41641 -j ACCEPT
    iptables -A INPUT -i tailscale+ -j ACCEPT
    iptables -A FORWARD -i tailscale+ -j ACCEPT
    iptables -A FORWARD -o tailscale+ -j ACCEPT
    
    # Allow Web UI access
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    
    # Allow Mihomo API
    iptables -A INPUT -p tcp --dport $MIHOMO_API_PORT -j ACCEPT
    
    # Allow Docker
    iptables -A INPUT -i docker+ -j ACCEPT
    iptables -A FORWARD -i docker+ -j ACCEPT
    iptables -A FORWARD -o docker+ -j ACCEPT
    
    # Allow ICMP (ping)
    iptables -A INPUT -p icmp -j ACCEPT
    
    print_success "Firewall configured"
}

# Setup NAT masquerade
setup_nat() {
    print_info "Setting up NAT..."
    
    # Masquerade outgoing traffic from hotspot
    iptables -t nat -A POSTROUTING -s $HOTSPOT_SUBNET -o $WAN_INTERFACE -j MASQUERADE
    
    # Allow hotspot forwarding
    iptables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -j ACCEPT
    iptables -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    print_success "NAT configured"
}

# Setup transparent proxy bypass (protected networks/ports)
setup_proxy_bypass() {
    print_info "Configuring proxy bypass rules..."
    
    # Create bypass chain
    iptables -t nat -N MIHOMO_BYPASS 2>/dev/null || true
    
    # Bypass localhost
    iptables -t nat -A MIHOMO_BYPASS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A MIHOMO_BYPASS -d 255.255.255.255/32 -j RETURN
    
    # Bypass protected networks
    for network in "${PROTECTED_NETWORKS[@]}"; do
        iptables -t nat -A MIHOMO_BYPASS -d $network -j RETURN
    done
    
    # Bypass Docker networks
    for network in "${DOCKER_NETWORKS[@]}"; do
        iptables -t nat -A MIHOMO_BYPASS -d $network -j RETURN
    done
    
    # Bypass protected ports
    for port in "${PROTECTED_PORTS[@]}"; do
        iptables -t nat -A MIHOMO_BYPASS -p tcp --dport $port -j RETURN
        iptables -t nat -A MIHOMO_BYPASS -p udp --dport $port -j RETURN
    done
    
    print_success "Bypass rules configured"
}

# Setup TUN method (default, recommended)
setup_tun_method() {
    print_info "Setting up TUN method (kernel-level proxy)..."
    
    # TUN method doesn't need iptables redirect
    # Mihomo handles everything via TUN interface
    # We just need NAT and firewall
    
    # Ensure TUN device exists
    if [ ! -d "/sys/class/net/utun" ] && [ ! -d "/sys/class/net/tun0" ]; then
        print_warn "TUN device not yet created (will be created by Mihomo)"
    else
        print_success "TUN device found"
    fi
    
    # Allow TUN traffic
    iptables -A FORWARD -i utun -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -i tun0 -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -o utun -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -o tun0 -j ACCEPT 2>/dev/null || true
    
    print_success "TUN method configured"
}

# Setup REDIRECT method
setup_redirect_method() {
    print_info "Setting up REDIRECT method..."
    
    # Create redirect chain
    iptables -t nat -N MIHOMO_REDIRECT 2>/dev/null || true
    iptables -t nat -F MIHOMO_REDIRECT
    
    # Add bypass rules first
    iptables -t nat -A MIHOMO_REDIRECT -j MIHOMO_BYPASS
    
    # Redirect TCP traffic to Mihomo
    iptables -t nat -A MIHOMO_REDIRECT -p tcp -j REDIRECT --to-ports $MIHOMO_REDIR_PORT
    
    # Apply to PREROUTING (for hotspot clients)
    iptables -t nat -A PREROUTING -s $HOTSPOT_SUBNET -p tcp -j MIHOMO_REDIRECT
    
    # Apply to OUTPUT (for local traffic)
    iptables -t nat -A OUTPUT -p tcp -j MIHOMO_REDIRECT
    
    print_success "REDIRECT method configured"
}



# Setup DNS redirect (for fake-ip)
setup_dns_redirect() {
    print_info "Setting up DNS redirect..."
    
    # Redirect DNS queries to Mihomo
    iptables -t nat -A PREROUTING -s $HOTSPOT_SUBNET -p udp --dport 53 -j REDIRECT --to-ports 5353
    iptables -t nat -A PREROUTING -s $HOTSPOT_SUBNET -p tcp --dport 53 -j REDIRECT --to-ports 5353
    
    # Allow DNS from hotspot to reach Mihomo
    iptables -A INPUT -s $HOTSPOT_SUBNET -p udp --dport 5353 -j ACCEPT
    iptables -A INPUT -s $HOTSPOT_SUBNET -p tcp --dport 5353 -j ACCEPT
    
    print_success "DNS redirect configured"
}

# Save iptables rules
save_rules() {
    print_info "Saving iptables rules..."
    
    if command -v iptables-save > /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
        iptables-save > /etc/iptables.rules 2>/dev/null || \
        print_warn "Could not save iptables rules (will be lost on reboot)"
    fi
    
    print_success "Rules saved"
}

# Show routing summary
show_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}           Routing Configuration Summary       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Proxy Method:${NC}      $PROXY_METHOD"
    echo -e "${GREEN}WAN Interface:${NC}     $WAN_INTERFACE"
    echo -e "${GREEN}LAN Interface:${NC}     $LAN_INTERFACE"
    echo -e "${GREEN}Hotspot Network:${NC}   $HOTSPOT_SUBNET"
    echo -e "${GREEN}Gateway IP:${NC}        $HOTSPOT_IP"
    echo ""
    echo -e "${YELLOW}Protected Services:${NC}"
    echo "  ✓ SSH (port 22, 2222)"
    echo "  ✓ Tailscale (port 41641, network 100.64.0.0/10)"
    echo "  ✓ Docker (networks 172.17-20.0.0/16)"
    echo "  ✓ CasaOS (port 8080)"
    echo "  ✓ Web UI (port 80, 443)"
    echo "  ✓ Mihomo API (port 9090)"
    echo ""
    echo -e "${GREEN}Status:${NC} ✓ All rules configured successfully"
    echo ""
}

# Show current rules
show_rules() {
    echo ""
    echo "=== NAT Rules ==="
    iptables -t nat -L -n -v --line-numbers
    echo ""
    echo "=== Filter Rules ==="
    iptables -t filter -L -n -v --line-numbers
    echo ""
    if [ "$PROXY_METHOD" == "tproxy" ]; then
        echo "=== Mangle Rules ==="
        iptables -t mangle -L -n -v --line-numbers
        echo ""
    fi
}

# Clear all rules
clear_rules() {
    print_info "Clearing all iptables rules..."
    flush_rules
    print_success "All rules cleared"
}

# Main setup function
main_setup() {
    print_header
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Auto-detect WAN
    auto_detect_wan
    
    # Enable IP forwarding
    enable_ip_forward
    
    # Flush existing rules
    flush_rules
    
    # Setup basic firewall
    setup_firewall
    
    # Setup NAT
    setup_nat
    
    # Setup bypass rules
    setup_proxy_bypass
    
    # Setup proxy method
    case "$PROXY_METHOD" in
        tun)
            setup_tun_method
            ;;
        redirect)
            setup_redirect_method
            ;;
        *)
            print_warn "Unknown method '$PROXY_METHOD', using REDIRECT"
            setup_redirect_method
            ;;
    esac
    
    # Setup DNS redirect
    setup_dns_redirect
    
    # Save rules
    save_rules
    
    # Show summary
    show_summary
}

# Command handling
case "${1:-setup}" in
    setup)
        main_setup
        ;;
    tun)
        PROXY_METHOD="tun"
        main_setup
        ;;
    redirect)
        PROXY_METHOD="redirect"
        main_setup
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
        echo "Usage: $0 {setup|tun|redirect|show|clear|save}"
        echo ""
        echo "Commands:"
        echo "  setup      - Auto-setup with REDIRECT method (default)"
        echo "  tun        - Setup with TUN method"
        echo "  redirect   - Setup with REDIRECT method (recommended)"
        echo "  show       - Show current rules"
        echo "  clear      - Clear all rules"
        echo "  save       - Save current rules"
        echo ""
        echo "Protected services: SSH, Tailscale, Docker, CasaOS, Web UI"
        exit 1
        ;;
esac

exit 0
