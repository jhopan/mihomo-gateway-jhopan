#!/bin/bash
# Smart Network Interface Detection Script
# Automatically detects internet connection (Ethernet, USB Tethering, WiFi)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Function to check if interface has internet
check_internet() {
    local interface=$1
    
    # Check if interface is up
    if ! ip link show "$interface" 2>/dev/null | grep -q "state UP"; then
        return 1
    fi
    
    # Check if interface has IP
    if ! ip addr show "$interface" 2>/dev/null | grep -q "inet "; then
        return 1
    fi
    
    # Try to ping through specific interface
    if ping -c 1 -W 2 -I "$interface" 8.8.8.8 &>/dev/null; then
        return 0
    fi
    
    return 1
}

# Function to detect USB tethering interface
detect_usb_tethering() {
    print_info "Detecting USB tethering interfaces..."
    
    # Common USB tethering interface patterns
    local usb_patterns=("usb" "rndis" "enp.*s.*u")
    
    for pattern in "${usb_patterns[@]}"; do
        for iface in $(ip link show | grep -oP "(?<=: )${pattern}[0-9a-z]+(?=:)"); do
            if check_internet "$iface"; then
                echo "$iface"
                return 0
            fi
        done
    done
    
    return 1
}

# Function to detect ethernet interface
detect_ethernet() {
    print_info "Detecting ethernet interfaces..."
    
    # Common ethernet patterns
    local eth_patterns=("eth" "enp" "eno")
    
    for pattern in "${eth_patterns[@]}"; do
        for iface in $(ip link show | grep -oP "(?<=: )${pattern}[0-9a-z]+(?=:)"); do
            # Skip USB interfaces
            if [[ $iface =~ usb ]] || [[ $iface =~ u[0-9] ]]; then
                continue
            fi
            
            if check_internet "$iface"; then
                echo "$iface"
                return 0
            fi
        done
    done
    
    return 1
}

# Function to detect WiFi interface with internet
detect_wifi_wan() {
    print_info "Detecting WiFi WAN interfaces..."
    
    for iface in $(iw dev 2>/dev/null | grep Interface | awk '{print $2}'); do
        # Check if connected to WiFi and has internet
        if iw dev "$iface" link 2>/dev/null | grep -q "Connected" && check_internet "$iface"; then
            echo "$iface"
            return 0
        fi
    done
    
    return 1
}

# Function to detect WiFi interface for hotspot (not connected)
detect_wifi_hotspot() {
    print_info "Detecting available WiFi interface for hotspot..."
    
    for iface in $(iw dev 2>/dev/null | grep Interface | awk '{print $2}'); do
        # Check if NOT connected (available for AP mode)
        if ! iw dev "$iface" link 2>/dev/null | grep -q "Connected"; then
            # Check if supports AP mode
            if iw list 2>/dev/null | grep -A 10 "Supported interface modes" | grep -q "* AP"; then
                echo "$iface"
                return 0
            fi
        fi
    done
    
    return 1
}

# Main detection function
detect_all_interfaces() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${CYAN}Smart Network Interface Detection${NC}               ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Detect WAN (Internet) interface
    print_info "Scanning for internet connection..."
    echo ""
    
    WAN_INTERFACE=""
    WAN_TYPE=""
    
    # Priority: USB Tethering > Ethernet > WiFi
    
    # 1. Try USB Tethering first
    if WAN_INTERFACE=$(detect_usb_tethering); then
        WAN_TYPE="USB Tethering"
        print_info "✓ Found USB Tethering: $WAN_INTERFACE"
    
    # 2. Try Ethernet
    elif WAN_INTERFACE=$(detect_ethernet); then
        WAN_TYPE="Ethernet"
        print_info "✓ Found Ethernet: $WAN_INTERFACE"
    
    # 3. Try WiFi
    elif WAN_INTERFACE=$(detect_wifi_wan); then
        WAN_TYPE="WiFi"
        print_info "✓ Found WiFi: $WAN_INTERFACE"
    else
        print_error "No internet connection found!"
        echo ""
        print_info "Available interfaces:"
        ip -br link show
        echo ""
        print_warn "Please connect to internet via:"
        echo "  - USB Tethering from phone"
        echo "  - Ethernet cable"
        echo "  - WiFi connection"
        return 1
    fi
    
    echo ""
    
    # Detect LAN interfaces
    print_info "Scanning for LAN interfaces..."
    echo ""
    
    LAN_INTERFACES=()
    
    # Get all interfaces except WAN
    for iface in $(ip -br link show | awk '{print $1}'); do
        # Skip loopback, WAN, and virtual interfaces
        if [[ $iface == "lo" ]] || [[ $iface == "$WAN_INTERFACE" ]] || [[ $iface =~ ^(docker|br-|veth) ]]; then
            continue
        fi
        
        # Check if interface exists and is not WAN
        if ip link show "$iface" &>/dev/null && [[ $iface != "$WAN_INTERFACE" ]]; then
            LAN_INTERFACES+=("$iface")
        fi
    done
    
    # Detect WiFi interface for hotspot
    WIFI_INTERFACE=""
    if WIFI_INTERFACE=$(detect_wifi_hotspot); then
        print_info "✓ Found WiFi for Hotspot: $WIFI_INTERFACE"
    else
        print_warn "No available WiFi interface for hotspot"
        WIFI_INTERFACE=""
    fi
    
    echo ""
    print_info "Other LAN interfaces: ${LAN_INTERFACES[*]:-None}"
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${GREEN}Detection Summary${NC}                                  ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} WAN (Internet):  ${YELLOW}$WAN_INTERFACE${NC} ($WAN_TYPE)"
    echo -e "${BLUE}║${NC} WiFi Hotspot:    ${YELLOW}${WIFI_INTERFACE:-Not Available}${NC}"
    echo -e "${BLUE}║${NC} Other LAN:       ${YELLOW}${LAN_INTERFACES[*]:-None}${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Save to config file
    CONFIG_FILE="/tmp/mihomo-interfaces.conf"
    cat > "$CONFIG_FILE" << EOF
# Auto-detected Network Interfaces
# Generated: $(date)

WAN_INTERFACE="$WAN_INTERFACE"
WAN_TYPE="$WAN_TYPE"
WIFI_INTERFACE="$WIFI_INTERFACE"
LAN_INTERFACES=(${LAN_INTERFACES[@]})
EOF
    
    print_info "Configuration saved to: $CONFIG_FILE"
    
    # Get WAN IP
    WAN_IP=$(ip -4 addr show "$WAN_INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    echo ""
    print_info "Connection Details:"
    echo "  Interface: $WAN_INTERFACE"
    echo "  Type: $WAN_TYPE"
    echo "  IP Address: $WAN_IP"
    echo "  Gateway: $(ip route | grep default | grep "$WAN_INTERFACE" | awk '{print $3}')"
    echo ""
    
    return 0
}

# Watch mode - continuous monitoring
watch_interfaces() {
    print_info "Starting interface monitoring... (Press Ctrl+C to stop)"
    echo ""
    
    while true; do
        clear
        detect_all_interfaces
        echo ""
        echo "Next check in 5 seconds..."
        sleep 5
    done
}

# Export function for use by other scripts
export_config() {
    if [ -f "/tmp/mihomo-interfaces.conf" ]; then
        source /tmp/mihomo-interfaces.conf
        
        echo "export WAN_INTERFACE=\"$WAN_INTERFACE\""
        echo "export WAN_TYPE=\"$WAN_TYPE\""
        echo "export WIFI_INTERFACE=\"$WIFI_INTERFACE\""
        echo "export LAN_INTERFACES=(${LAN_INTERFACES[@]})"
    else
        print_error "Config file not found. Run detection first."
        return 1
    fi
}

# Test internet connection
test_connection() {
    if [ -f "/tmp/mihomo-interfaces.conf" ]; then
        source /tmp/mihomo-interfaces.conf
        
        echo -e "${BLUE}Testing Internet Connection...${NC}"
        echo ""
        
        # Test DNS
        print_info "Testing DNS resolution..."
        if nslookup google.com &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} DNS working"
        else
            echo -e "  ${RED}✗${NC} DNS failed"
        fi
        
        # Test HTTP
        print_info "Testing HTTP connection..."
        if curl -s --max-time 5 http://www.google.com &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} HTTP working"
        else
            echo -e "  ${RED}✗${NC} HTTP failed"
        fi
        
        # Test HTTPS
        print_info "Testing HTTPS connection..."
        if curl -s --max-time 5 https://www.google.com &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} HTTPS working"
        else
            echo -e "  ${RED}✗${NC} HTTPS failed"
        fi
        
        # Speed test (simple)
        print_info "Testing speed (download 1MB)..."
        SPEED=$(curl -s -w "%{speed_download}" -o /dev/null --max-time 10 http://speedtest.tele2.net/1MB.zip)
        SPEED_MBPS=$(echo "scale=2; $SPEED / 1024 / 1024 * 8" | bc)
        echo -e "  Speed: ${YELLOW}${SPEED_MBPS} Mbps${NC}"
        
    else
        print_error "Run detection first: sudo bash $0 detect"
        return 1
    fi
}

# Main script
case "${1:-detect}" in
    detect)
        detect_all_interfaces
        ;;
    watch)
        watch_interfaces
        ;;
    export)
        export_config
        ;;
    test)
        test_connection
        ;;
    *)
        echo "Usage: $0 {detect|watch|export|test}"
        echo ""
        echo "Commands:"
        echo "  detect  - Detect network interfaces once (default)"
        echo "  watch   - Continuously monitor interfaces"
        echo "  export  - Export detected config for other scripts"
        echo "  test    - Test internet connection"
        echo ""
        exit 1
        ;;
esac
