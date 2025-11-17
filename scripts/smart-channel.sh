#!/bin/bash
# Smart WiFi Channel Selection Script
# Auto-detects available channels and selects the best one

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

# Function to get supported channels
get_supported_channels() {
    local interface=$1
    local band=$2  # 2.4GHz or 5GHz
    
    if [ "$band" = "5GHz" ]; then
        # 5GHz channels
        iw phy "$(iw dev "$interface" info | grep wiphy | awk '{print $2}')" channels 2>/dev/null | \
            grep -E "^\s+\* [0-9]+ MHz \[[0-9]+\]" | \
            grep -v "disabled\|passive\|radar" | \
            awk '{print $4}' | \
            tr -d '[]'
    else
        # 2.4GHz channels (default)
        iw phy "$(iw dev "$interface" info | grep wiphy | awk '{print $2}')" channels 2>/dev/null | \
            grep -E "^\s+\* 2[0-9]{3} MHz \[[0-9]+\]" | \
            grep -v "disabled\|passive\|radar" | \
            awk '{print $4}' | \
            tr -d '[]'
    fi
}

# Function to scan nearby networks
scan_nearby_networks() {
    local interface=$1
    
    print_info "Scanning nearby networks..."
    
    # Make sure interface is up
    ip link set "$interface" up 2>/dev/null
    
    # Scan
    iw dev "$interface" scan 2>/dev/null | \
        grep -E "freq:|signal:" | \
        paste - - | \
        awk '{print $2, $4}' | \
        while read freq signal; do
            # Convert frequency to channel
            if [ "$freq" -ge 2412 ] && [ "$freq" -le 2484 ]; then
                channel=$(( (freq - 2412) / 5 + 1 ))
                echo "$channel $signal"
            elif [ "$freq" -ge 5000 ]; then
                channel=$(( (freq - 5000) / 5 ))
                echo "$channel $signal"
            fi
        done
}

# Function to analyze channel usage
analyze_channels() {
    local interface=$1
    local supported_channels=("$@")
    
    # Remove interface from args
    supported_channels=("${@:2}")
    
    print_info "Analyzing channel usage..."
    
    # Create associative array for channel scores
    declare -A channel_scores
    
    # Initialize all supported channels with score 100
    for ch in "${supported_channels[@]}"; do
        channel_scores[$ch]=100
    done
    
    # Scan and reduce scores for busy channels
    while IFS= read -r line; do
        channel=$(echo "$line" | awk '{print $1}')
        signal=$(echo "$line" | awk '{print $2}')
        
        # Convert signal to positive number
        signal=${signal#-}
        
        # If channel is supported, reduce score
        if [[ -v channel_scores[$channel] ]]; then
            # Stronger signal = worse score
            penalty=$(( signal / 10 ))
            channel_scores[$channel]=$(( channel_scores[$channel] - penalty ))
        fi
        
        # Also penalize adjacent channels
        for adj in $(seq $((channel-2)) $((channel+2))); do
            if [[ -v channel_scores[$adj] ]] && [ "$adj" != "$channel" ]; then
                channel_scores[$adj]=$(( channel_scores[$adj] - (penalty / 2) ))
            fi
        done
    done < <(scan_nearby_networks "$interface")
    
    # Find best channel
    best_channel=""
    best_score=0
    
    for ch in "${!channel_scores[@]}"; do
        score=${channel_scores[$ch]}
        if [ "$score" -gt "$best_score" ]; then
            best_score=$score
            best_channel=$ch
        fi
    done
    
    echo "$best_channel"
}

# Function to select best channel
select_best_channel() {
    local interface=$1
    local preferred_channel=${2:-"auto"}
    local band=${3:-"2.4GHz"}
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${CYAN}Smart WiFi Channel Selection${NC}                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if interface exists
    if ! ip link show "$interface" &>/dev/null; then
        print_error "Interface $interface not found!"
        return 1
    fi
    
    # Check if wireless
    if ! iw dev "$interface" info &>/dev/null; then
        print_error "$interface is not a wireless interface!"
        return 1
    fi
    
    # Get supported channels
    print_info "Getting supported channels for $interface ($band)..."
    readarray -t supported_channels < <(get_supported_channels "$interface" "$band")
    
    if [ ${#supported_channels[@]} -eq 0 ]; then
        print_error "No supported channels found!"
        return 1
    fi
    
    print_info "Supported channels: ${supported_channels[*]}"
    echo ""
    
    # If preferred channel is specified and supported, use it
    if [ "$preferred_channel" != "auto" ]; then
        if [[ " ${supported_channels[*]} " =~ " ${preferred_channel} " ]]; then
            print_info "Using preferred channel: $preferred_channel"
            echo "$preferred_channel"
            return 0
        else
            print_warn "Preferred channel $preferred_channel not supported!"
            print_info "Available channels: ${supported_channels[*]}"
            print_info "Falling back to auto-selection..."
            echo ""
        fi
    fi
    
    # Auto-select best channel
    print_info "Analyzing network environment..."
    best_channel=$(analyze_channels "$interface" "${supported_channels[@]}")
    
    if [ -z "$best_channel" ]; then
        # Fallback to first supported channel
        best_channel=${supported_channels[0]}
        print_warn "Could not determine best channel, using: $best_channel"
    else
        print_info "Best channel determined: $best_channel"
    fi
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${GREEN}Selected Channel: $best_channel${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Save to config
    echo "$best_channel" > /tmp/mihomo-wifi-channel.conf
    
    echo "$best_channel"
    return 0
}

# Function to show channel information
show_channel_info() {
    local interface=$1
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${CYAN}WiFi Channel Information${NC}                         ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get supported 2.4GHz channels
    print_info "2.4GHz Supported Channels:"
    readarray -t channels_24 < <(get_supported_channels "$interface" "2.4GHz")
    echo "  ${channels_24[*]}"
    echo ""
    
    # Get supported 5GHz channels
    print_info "5GHz Supported Channels:"
    readarray -t channels_5 < <(get_supported_channels "$interface" "5GHz")
    if [ ${#channels_5[@]} -gt 0 ]; then
        echo "  ${channels_5[*]}"
    else
        echo "  Not supported or no channels available"
    fi
    echo ""
    
    # Show nearby networks
    print_info "Nearby Networks:"
    echo ""
    printf "  %-10s %-10s\n" "Channel" "Signal"
    echo "  ────────────────────"
    
    while IFS= read -r line; do
        channel=$(echo "$line" | awk '{print $1}')
        signal=$(echo "$line" | awk '{print $2}')
        printf "  %-10s %-10s dBm\n" "$channel" "$signal"
    done < <(scan_nearby_networks "$interface")
    
    echo ""
}

# Function to test channel
test_channel() {
    local interface=$1
    local channel=$2
    
    print_info "Testing channel $channel on $interface..."
    
    # Check if channel is supported
    readarray -t supported < <(get_supported_channels "$interface" "2.4GHz")
    
    if [[ ! " ${supported[*]} " =~ " ${channel} " ]]; then
        print_error "Channel $channel is NOT supported!"
        print_info "Supported channels: ${supported[*]}"
        return 1
    else
        print_info "Channel $channel is supported ✓"
        return 0
    fi
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <interface> [command] [options]"
    echo ""
    echo "Commands:"
    echo "  auto [band]          - Auto-select best channel (default: 2.4GHz)"
    echo "  select <channel>     - Select specific channel if supported"
    echo "  info                 - Show channel information"
    echo "  test <channel>       - Test if channel is supported"
    echo "  scan                 - Scan nearby networks"
    echo ""
    echo "Examples:"
    echo "  $0 wlan0 auto"
    echo "  $0 wlan0 select 6"
    echo "  $0 wlan0 info"
    echo "  $0 wlan0 test 11"
    echo ""
    exit 1
fi

INTERFACE=$1
COMMAND=${2:-"auto"}

case "$COMMAND" in
    auto)
        BAND=${3:-"2.4GHz"}
        select_best_channel "$INTERFACE" "auto" "$BAND"
        ;;
    select)
        CHANNEL=$3
        if [ -z "$CHANNEL" ]; then
            print_error "Please specify channel number"
            exit 1
        fi
        select_best_channel "$INTERFACE" "$CHANNEL"
        ;;
    info)
        show_channel_info "$INTERFACE"
        ;;
    test)
        CHANNEL=$3
        if [ -z "$CHANNEL" ]; then
            print_error "Please specify channel number"
            exit 1
        fi
        test_channel "$INTERFACE" "$CHANNEL"
        ;;
    scan)
        scan_nearby_networks "$INTERFACE"
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        exit 1
        ;;
esac
