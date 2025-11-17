#!/bin/bash
# Monitoring Script for Mihomo Gateway

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MIHOMO_API="http://127.0.0.1:9090"
REFRESH_INTERVAL=2

# Function to get traffic data
get_traffic() {
    curl -s "$MIHOMO_API/traffic" 2>/dev/null
}

# Function to get connections
get_connections() {
    curl -s "$MIHOMO_API/connections" 2>/dev/null
}

# Function to get proxies
get_proxies() {
    curl -s "$MIHOMO_API/proxies" 2>/dev/null
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(($bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(($bytes / 1048576))MB"
    else
        echo "$(($bytes / 1073741824))GB"
    fi
}

# Function to display header
display_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}        ${CYAN}Mihomo Gateway - Real-time Monitor${NC}              ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to display system info
display_system_info() {
    echo -e "${GREEN}System Information:${NC}"
    echo -e "  Date/Time: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "  Hostname: ${YELLOW}$(hostname)${NC}"
    echo -e "  Uptime: ${YELLOW}$(uptime -p)${NC}"
    
    # Check Mihomo status
    if systemctl is-active --quiet mihomo; then
        echo -e "  Mihomo: ${GREEN}Running${NC}"
    else
        echo -e "  Mihomo: ${RED}Stopped${NC}"
    fi
    
    echo ""
}

# Function to display traffic
display_traffic() {
    local traffic=$(get_traffic)
    
    if [ -n "$traffic" ]; then
        local up=$(echo $traffic | grep -oP '(?<="up":)[0-9]+')
        local down=$(echo $traffic | grep -oP '(?<="down":)[0-9]+')
        
        echo -e "${GREEN}Traffic Statistics:${NC}"
        echo -e "  Upload: ${YELLOW}$(format_bytes $up)/s${NC}"
        echo -e "  Download: ${YELLOW}$(format_bytes $down)/s${NC}"
    else
        echo -e "${RED}Unable to get traffic data${NC}"
    fi
    
    echo ""
}

# Function to display connections
display_connections() {
    local connections=$(get_connections)
    
    if [ -n "$connections" ]; then
        local count=$(echo $connections | grep -o '"id"' | wc -l)
        
        echo -e "${GREEN}Active Connections: ${YELLOW}$count${NC}"
        
        # Show top 10 connections
        echo ""
        echo -e "${CYAN}Recent Connections:${NC}"
        echo $connections | jq -r '.connections[:10][] | "\(.metadata.sourceIP) -> \(.metadata.host // .metadata.destinationIP) [\(.chains[-1])]"' 2>/dev/null | head -10 | while read line; do
            echo -e "  ${line}"
        done
    else
        echo -e "${RED}Unable to get connections data${NC}"
    fi
    
    echo ""
}

# Function to display network interfaces
display_interfaces() {
    echo -e "${GREEN}Network Interfaces:${NC}"
    
    ip -br addr show | while read iface status addr rest; do
        if [ "$status" = "UP" ]; then
            echo -e "  ${GREEN}●${NC} $iface - $addr"
        else
            echo -e "  ${RED}●${NC} $iface - $status"
        fi
    done
    
    echo ""
}

# Function to display resource usage
display_resources() {
    echo -e "${GREEN}Resource Usage:${NC}"
    
    # CPU
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "  CPU: ${YELLOW}${cpu}%${NC}"
    
    # Memory
    local mem=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    echo -e "  Memory: ${YELLOW}${mem}%${NC}"
    
    # Disk
    local disk=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "  Disk: ${YELLOW}${disk}${NC}"
    
    # Mihomo process
    if pgrep -x mihomo > /dev/null; then
        local mihomo_cpu=$(ps aux | grep mihomo | grep -v grep | awk '{print $3}')
        local mihomo_mem=$(ps aux | grep mihomo | grep -v grep | awk '{print $4}')
        echo -e "  Mihomo CPU: ${YELLOW}${mihomo_cpu}%${NC}"
        echo -e "  Mihomo Memory: ${YELLOW}${mihomo_mem}%${NC}"
    fi
    
    echo ""
}

# Function to display hotspot info
display_hotspot() {
    if systemctl is-active --quiet hostapd; then
        echo -e "${GREEN}Hotspot Status: ${GREEN}Active${NC}"
        
        # Count connected clients
        if [ -f /var/lib/misc/dnsmasq.leases ]; then
            local clients=$(wc -l < /var/lib/misc/dnsmasq.leases)
            echo -e "  Connected clients: ${YELLOW}$clients${NC}"
        fi
    else
        echo -e "${GREEN}Hotspot Status: ${RED}Inactive${NC}"
    fi
    
    echo ""
}

# Main monitoring loop
monitor_realtime() {
    while true; do
        display_header
        display_system_info
        display_traffic
        display_connections
        display_interfaces
        display_hotspot
        display_resources
        
        echo -e "${BLUE}Press Ctrl+C to exit${NC}"
        
        sleep $REFRESH_INTERVAL
    done
}

# Function to show simple stats
show_stats() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Mihomo Gateway Statistics${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    # System info
    echo -e "${CYAN}System:${NC}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  Uptime: $(uptime -p)"
    echo ""
    
    # Mihomo status
    echo -e "${CYAN}Mihomo:${NC}"
    if systemctl is-active --quiet mihomo; then
        echo -e "  Status: ${GREEN}Running${NC}"
        echo -e "  Port: 7890 (HTTP), 7891 (SOCKS5), 7892 (Mixed)"
    else
        echo -e "  Status: ${RED}Stopped${NC}"
    fi
    echo ""
    
    # Current traffic
    local traffic=$(get_traffic)
    if [ -n "$traffic" ]; then
        local up=$(echo $traffic | grep -oP '(?<="up":)[0-9]+')
        local down=$(echo $traffic | grep -oP '(?<="down":)[0-9]+')
        
        echo -e "${CYAN}Current Traffic:${NC}"
        echo -e "  Upload: $(format_bytes $up)/s"
        echo -e "  Download: $(format_bytes $down)/s"
    fi
    echo ""
    
    # Connections
    local connections=$(get_connections)
    if [ -n "$connections" ]; then
        local count=$(echo $connections | grep -o '"id"' | wc -l)
        echo -e "${CYAN}Connections:${NC}"
        echo -e "  Active: $count"
    fi
    echo ""
    
    # Hotspot
    if systemctl is-active --quiet hostapd; then
        echo -e "${CYAN}Hotspot:${NC}"
        echo -e "  Status: ${GREEN}Active${NC}"
        if [ -f /var/lib/misc/dnsmasq.leases ]; then
            echo -e "  Clients: $(wc -l < /var/lib/misc/dnsmasq.leases)"
        fi
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

# Function to test connectivity
test_connectivity() {
    echo -e "${BLUE}Testing Connectivity...${NC}"
    echo ""
    
    # Test direct connection
    echo -e "${CYAN}Direct connection:${NC}"
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://www.google.com > /dev/null; then
        echo -e "  ${GREEN}✓${NC} Internet accessible"
    else
        echo -e "  ${RED}✗${NC} No internet connection"
    fi
    echo ""
    
    # Test through Mihomo
    echo -e "${CYAN}Through Mihomo proxy:${NC}"
    if curl -x http://127.0.0.1:7890 -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://www.google.com > /dev/null; then
        echo -e "  ${GREEN}✓${NC} Proxy working"
    else
        echo -e "  ${RED}✗${NC} Proxy not working"
    fi
    echo ""
    
    # Test Mihomo API
    echo -e "${CYAN}Mihomo API:${NC}"
    if curl -s "$MIHOMO_API/version" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} API accessible"
        local version=$(curl -s "$MIHOMO_API/version" | jq -r '.version' 2>/dev/null)
        if [ -n "$version" ]; then
            echo -e "  Version: $version"
        fi
    else
        echo -e "  ${RED}✗${NC} API not accessible"
    fi
    echo ""
}

# Main script
case "${1:-monitor}" in
    monitor)
        # Check if jq is installed
        if ! command -v jq &> /dev/null; then
            echo "Installing jq for JSON parsing..."
            apt-get install -y jq
        fi
        
        monitor_realtime
        ;;
    stats)
        show_stats
        ;;
    test)
        test_connectivity
        ;;
    *)
        echo "Mihomo Gateway - Monitoring Script"
        echo ""
        echo "Usage: $0 {monitor|stats|test}"
        echo ""
        echo "Commands:"
        echo "  monitor  - Real-time monitoring (default)"
        echo "  stats    - Show current statistics"
        echo "  test     - Test connectivity"
        echo ""
        exit 1
        ;;
esac
