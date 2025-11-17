#!/bin/bash
# Client Monitoring & Static IP Management
# Monitor connected clients dan manage DHCP static leases

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DNSMASQ_STATIC="/etc/dnsmasq.d/static-leases.conf"
CLIENTS_DB="/var/lib/mihomo/clients.db"

# Colors
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

# Initialize clients database
init_db() {
    mkdir -p /var/lib/mihomo
    if [ ! -f "$CLIENTS_DB" ]; then
        echo "# Mihomo Gateway - Connected Clients Database" > "$CLIENTS_DB"
        echo "# Format: MAC_ADDRESS|IP_ADDRESS|HOSTNAME|FIRST_SEEN|LAST_SEEN|COMMENT" >> "$CLIENTS_DB"
    fi
}

# Get connected clients from ARP table
get_connected_clients() {
    echo "==================================="
    echo "  Connected Clients (Hotspot)"
    echo "==================================="
    printf "%-18s %-15s %-20s %-10s\n" "MAC Address" "IP Address" "Hostname" "Status"
    echo "-----------------------------------"
    
    # Parse ARP table for 192.168.1.x
    ip neigh show dev wlan0 | while read line; do
        ip=$(echo $line | awk '{print $1}')
        mac=$(echo $line | awk '{print $5}')
        state=$(echo $line | awk '{print $6}')
        
        # Get hostname from dnsmasq leases
        hostname=$(grep "$mac" /var/lib/misc/dnsmasq.leases 2>/dev/null | awk '{print $4}' || echo "-")
        
        # Show only active clients
        if [ "$state" == "REACHABLE" ] || [ "$state" == "STALE" ]; then
            printf "%-18s %-15s %-20s %-10s\n" "$mac" "$ip" "$hostname" "$state"
            
            # Update database
            update_client_db "$mac" "$ip" "$hostname"
        fi
    done
}

# Update client database
update_client_db() {
    local mac=$1
    local ip=$2
    local hostname=$3
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    
    init_db
    
    # Check if client exists
    if grep -q "^$mac|" "$CLIENTS_DB"; then
        # Update last seen
        sed -i "s|^$mac|.*|$mac|$ip|$hostname|.*|$now|" "$CLIENTS_DB"
    else
        # Add new client
        echo "$mac|$ip|$hostname|$now|$now|" >> "$CLIENTS_DB"
    fi
}

# Show client history
show_client_history() {
    init_db
    
    echo "==================================="
    echo "  Client History"
    echo "==================================="
    printf "%-18s %-15s %-20s %-20s\n" "MAC Address" "IP Address" "Hostname" "Last Seen"
    echo "-----------------------------------"
    
    tail -n +3 "$CLIENTS_DB" | while IFS='|' read mac ip hostname first_seen last_seen comment; do
        printf "%-18s %-15s %-20s %-20s\n" "$mac" "$ip" "$hostname" "$last_seen"
    done
}

# Add static IP lease
add_static_lease() {
    local mac=$1
    local ip=$2
    local hostname=$3
    
    if [ -z "$mac" ] || [ -z "$ip" ]; then
        echo "Usage: $0 add-static <MAC> <IP> [hostname]"
        echo "Example: $0 add-static aa:bb:cc:dd:ee:ff 192.168.1.50 MyPhone"
        exit 1
    fi
    
    # Validate IP in range
    if [[ ! "$ip" =~ ^192\.168\.1\.[0-9]+$ ]]; then
        print_warn "IP must be in range 192.168.1.0/24"
        exit 1
    fi
    
    # Create static leases file if not exists
    if [ ! -f "$DNSMASQ_STATIC" ]; then
        echo "# Static DHCP Leases for Mihomo Gateway" | sudo tee "$DNSMASQ_STATIC" > /dev/null
    fi
    
    # Check if already exists
    if sudo grep -q "$mac" "$DNSMASQ_STATIC"; then
        print_warn "Static lease for $mac already exists. Updating..."
        sudo sed -i "/$mac/d" "$DNSMASQ_STATIC"
    fi
    
    # Add static lease
    if [ -n "$hostname" ]; then
        echo "dhcp-host=$mac,$ip,$hostname,infinite" | sudo tee -a "$DNSMASQ_STATIC" > /dev/null
    else
        echo "dhcp-host=$mac,$ip,infinite" | sudo tee -a "$DNSMASQ_STATIC" > /dev/null
    fi
    
    print_info "Static lease added: $mac -> $ip"
    
    # Restart dnsmasq
    print_info "Restarting dnsmasq..."
    sudo systemctl restart dnsmasq
    
    print_info "Done! Device $mac will always get IP $ip"
}

# Remove static lease
remove_static_lease() {
    local mac=$1
    
    if [ -z "$mac" ]; then
        echo "Usage: $0 remove-static <MAC>"
        exit 1
    fi
    
    if [ ! -f "$DNSMASQ_STATIC" ]; then
        print_warn "No static leases configured"
        exit 1
    fi
    
    sudo sed -i "/$mac/d" "$DNSMASQ_STATIC"
    print_info "Static lease removed for $mac"
    
    sudo systemctl restart dnsmasq
}

# List static leases
list_static_leases() {
    if [ ! -f "$DNSMASQ_STATIC" ]; then
        print_warn "No static leases configured"
        exit 0
    fi
    
    echo "==================================="
    echo "  Static IP Leases"
    echo "==================================="
    printf "%-18s %-15s %-20s\n" "MAC Address" "IP Address" "Hostname"
    echo "-----------------------------------"
    
    grep "^dhcp-host=" "$DNSMASQ_STATIC" | while read line; do
        # Parse dhcp-host=MAC,IP,hostname,infinite
        mac=$(echo $line | cut -d'=' -f2 | cut -d',' -f1)
        ip=$(echo $line | cut -d',' -f2)
        hostname=$(echo $line | cut -d',' -f3)
        
        printf "%-18s %-15s %-20s\n" "$mac" "$ip" "$hostname"
    done
}

# Monitor in real-time
monitor_realtime() {
    print_info "Starting real-time monitoring (Ctrl+C to stop)"
    echo ""
    
    while true; do
        clear
        echo "Mihomo Gateway - Client Monitor"
        echo "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        get_connected_clients
        echo ""
        echo "Press Ctrl+C to stop"
        sleep 5
    done
}

# Export to JSON (for web dashboard)
export_json() {
    local output_file="${1:-/var/www/html/mihomo-ui/clients.json}"
    
    echo "{" > "$output_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$output_file"
    echo "  \"clients\": [" >> "$output_file"
    
    first=true
    ip neigh show dev wlan0 | while read line; do
        ip=$(echo $line | awk '{print $1}')
        mac=$(echo $line | awk '{print $5}')
        state=$(echo $line | awk '{print $6}')
        
        if [ "$state" == "REACHABLE" ] || [ "$state" == "STALE" ]; then
            hostname=$(grep "$mac" /var/lib/misc/dnsmasq.leases 2>/dev/null | awk '{print $4}' || echo "unknown")
            
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "$output_file"
            fi
            
            echo "    {" >> "$output_file"
            echo "      \"mac\": \"$mac\"," >> "$output_file"
            echo "      \"ip\": \"$ip\"," >> "$output_file"
            echo "      \"hostname\": \"$hostname\"," >> "$output_file"
            echo "      \"state\": \"$state\"" >> "$output_file"
            echo -n "    }" >> "$output_file"
        fi
    done
    
    echo "" >> "$output_file"
    echo "  ]" >> "$output_file"
    echo "}" >> "$output_file"
    
    print_info "Client list exported to $output_file"
}

# Main
case "${1:-list}" in
    list)
        get_connected_clients
        ;;
    history)
        show_client_history
        ;;
    static)
        list_static_leases
        ;;
    add-static)
        add_static_lease "$2" "$3" "$4"
        ;;
    remove-static)
        remove_static_lease "$2"
        ;;
    monitor)
        monitor_realtime
        ;;
    json)
        export_json "$2"
        ;;
    *)
        echo "Mihomo Gateway - Client Monitoring"
        echo ""
        echo "Usage: $0 {list|history|static|add-static|remove-static|monitor|json}"
        echo ""
        echo "Commands:"
        echo "  list              - Show currently connected clients"
        echo "  history           - Show all clients history"
        echo "  static            - List static IP leases"
        echo "  add-static        - Add static IP for a device"
        echo "                      Example: $0 add-static aa:bb:cc:dd:ee:ff 192.168.1.50 MyPhone"
        echo "  remove-static     - Remove static IP lease"
        echo "                      Example: $0 remove-static aa:bb:cc:dd:ee:ff"
        echo "  monitor           - Real-time monitoring (auto-refresh)"
        echo "  json              - Export client list to JSON (for web UI)"
        echo ""
        echo "Examples:"
        echo "  # Show connected clients"
        echo "  sudo bash $0 list"
        echo ""
        echo "  # Add static IP for your phone"
        echo "  sudo bash $0 add-static aa:bb:cc:dd:ee:ff 192.168.1.100 MyPhone"
        echo ""
        echo "  # Monitor in real-time"
        echo "  sudo bash $0 monitor"
        exit 1
        ;;
esac
