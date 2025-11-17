#!/bin/bash
# Speedtest API endpoint for web dashboard
# Requires: speedtest-cli installed

set -e

# Check if speedtest is installed
if ! command -v speedtest &> /dev/null; then
    echo '{"error": "speedtest-cli not installed"}'
    exit 1
fi

# Function to run speedtest and format output
run_speedtest() {
    local format=${1:-json}
    
    if [ "$format" == "json" ]; then
        # Run speedtest with JSON output
        speedtest --json 2>/dev/null || echo '{"error": "speedtest failed"}'
    else
        # Run speedtest with simple output
        speedtest --simple 2>/dev/null || echo "Error: speedtest failed"
    fi
}

# Function to get last speedtest result from cache
get_cached_result() {
    local cache_file="/tmp/mihomo-speedtest-cache.json"
    
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        echo '{"error": "no cached result", "message": "Run speedtest first"}'
    fi
}

# Function to save speedtest result to cache
save_to_cache() {
    local cache_file="/tmp/mihomo-speedtest-cache.json"
    local result="$1"
    
    echo "$result" > "$cache_file"
}

# Main
case "${1:-run}" in
    run)
        echo "Running speedtest..."
        result=$(run_speedtest json)
        save_to_cache "$result"
        echo "$result"
        ;;
    cached)
        get_cached_result
        ;;
    simple)
        run_speedtest simple
        ;;
    *)
        echo "Usage: $0 {run|cached|simple}"
        exit 1
        ;;
esac
