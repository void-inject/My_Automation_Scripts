#!/usr/bin/env bash

# Static Configuration for Telegram Bot
BOT_TOKEN="<YOUR_BOT_TOKEN>" # Replace with your bot's token
CHAT_ID="<YOUR_CHAT_ID>"     # Replace with your chat ID

LOG_FILE="watchdog.log"

# Function to display usage instructions
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p <IP> <WATCHED_PORT>"
    echo "  -h <IP_RANGE> <KNOWN_HOSTS_FILE> <INTERFACE>"
    echo
    echo "Info:"
    echo "  -p  Monitor a specific port on a target (e.g., 192.168.1.1 22)"
    echo "  -h  Perform host discovery (e.g., 192.168.1.0/24 192-168-1-host.txt eth0)"
    exit 1
}

# Variables for options
IP=""
IP_RANGE=""
WATCHED_PORT=""
KNOWN_HOSTS_FILE=""
INTERFACE=""

# Parse flags and arguments
parse_flags() {
    while getopts "p:h:" opt; do
        case $opt in
        p)
            IP="$OPTARG"
            WATCHED_PORT="$2"
            shift 2
            ;;
        h)
            IP_RANGE="$OPTARG"
            KNOWN_HOSTS_FILE="$3"
            INTERFACE="$4"
            shift 3
            ;;
        *)
            usage
            ;;
        esac
    done
}

# Validate inputs
validate_inputs() {
    if [ -z "$IP" ] && [ -z "$IP_RANGE" ]; then
        echo "Error: Missing required parameters."
        usage
    fi
}

# Setup new host file
setup_new_host_file() {
    NEW_HOST="${KNOWN_HOSTS_FILE%.txt}-new.txt"
    touch "$NEW_HOST" || {
        echo "Failed to create ${NEW_HOST}"
        exit 1
    }
}

# Function to send a message via Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${message}" >/dev/null || {
        echo "Failed to send Telegram message."
    }
}

# Host discovery function
host_discovery() {
    sudo arp-scan -x -I "$INTERFACE" "$IP_RANGE" | while read -r line; do
        host=$(echo "$line" | awk '{print $1}')
        [ -z "$host" ] && continue
        if ! grep -q "$host" "$KNOWN_HOSTS_FILE"; then
            DATE=$(date '+%H:%M %d/%m/%Y')
            echo "New host detected: $host at $DATE"
            echo "$host" >>"$NEW_HOST"
            send_telegram_message "🚨 New host detected: $host at $DATE"
        fi
    done
}

# Port monitoring function
monitor_port() {
    echo "Monitoring port $WATCHED_PORT on $IP"
    while true; do
        if port_scan=$(docker run --network=host -it --rm \
            --name rustscan rustscan/rustscan:2.1.1 \
            -a "$IP" -g -p "$WATCHED_PORT"); then
            echo "Port $WATCHED_PORT is open on $IP"
            send_telegram_message "🚨 Port $WATCHED_PORT is now open on $IP. Details logged."
            break
        else
            echo "Port $WATCHED_PORT is not open yet. Retrying in 300 seconds..."
            sleep 300
        fi
    done
}

# Main execution
parse_flags "$@"
validate_inputs

# Run both functions in the background if both are provided
if [ -n "$IP" ] && [ -n "$WATCHED_PORT" ]; then
    monitor_port &
fi

if [ -n "$IP_RANGE" ] && [ -n "$KNOWN_HOSTS_FILE" ] && [ -n "$INTERFACE" ]; then
    setup_new_host_file
    host_discovery &
fi

# Wait for both background processes to finish
wait
