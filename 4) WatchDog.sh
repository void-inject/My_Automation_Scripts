#!/usr/bin/env bash

# Static Configuration for Telegram Bot
BOT_TOKEN="<YOUR_BOT_TOKEN>" # Replace with your bot's token
CHAT_ID="<YOUR_CHAT_ID>"     # Replace with your chat ID

LOG_FILE="watchdog.log"

# Function to display usage instructions
usage() {
    echo "Usage: "
    echo "  $0 [-p <TARGET> <WATCHED_PORT>]"
    echo "  $0 [-h <TARGET> <KNOWN_HOSTS_FILE> <INTERFACE>]"
    echo "  $0 [-hp <TARGET> <WATCHED_PORT> <KNOWN_HOSTS_FILE> <INTERFACE>]"
    echo
    echo "Flags:"
    echo "  -p  Monitor a specific port on a target (e.g., 192.168.1.1 22)"
    echo "  -h  Perform host discovery (requires target, known hosts file, and interface)"
    echo "  -hp Combine host discovery and port monitoring"
    exit 1
}

# Variables for options
MODE=""
TARGET=""
WATCHED_PORT=""
KNOWN_HOSTS_FILE=""
INTERFACE=""

# Parse flags and arguments
parse_flags() {
    while getopts ":p:h:" opt; do
        case $opt in
        p)
            MODE="p"
            TARGET=$OPTARG
            WATCHED_PORT=${!OPTIND} # Get the next argument
            shift 2
            ;;
        h)
            if [[ $MODE == "p" ]]; then
                MODE="hp"
            else
                MODE="h"
            fi
            KNOWN_HOSTS_FILE=${!OPTIND} # Get the next argument
            INTERFACE=${!OPTIND+1}      # Get the following argument
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
    if [ -z "$MODE" || -z "$TARGET" ]; then
        echo "Error: Missing required parameters."
        usage
    fi
}

# Derive NEW_HOSTS file name from KNOWN_HOSTS_FILE if provided
setup_new_host_file() {
    NEW_HOST=""
    if [ -n "$KNOWN_HOSTS_FILE" ]; then
        NEW_HOST="${KNOWN_HOSTS_FILE/host/new}"
        touch "$NEW_HOST" || {
            echo "Failed to create ${NEW_HOST}"
            exit 1
        }
    fi
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

# Function to perform service discovery
service_discovery() {
    local host=$1
    local port=$2
    nmap -sV -p "$port" "$host" >>"${LOG_FILE}"
}

# Function for host discovery
host_discovery() {
    sudo arp-scan -x -I "$INTERFACE" "$TARGET" | while read -r line; do
        local host=$(echo "$line" | awk '{print $1}')
        if ! grep -q "$host" "$KNOWN_HOSTS_FILE"; then
            local DATE=$(date '+%H:%M %d/%m/%Y')
            echo "New host detected: $host at $DATE"
            echo "$host" >>"$NEW_HOST"
            send_telegram_message "\ud83d\udea8 New host detected: $host at $DATE"
        fi
    done
}

# Function to monitor port and send alerts
monitor_port() {
    echo "Monitoring port $WATCHED_PORT on $TARGET"
    while true; do
        port_scan=$(docker run --network=host -it --rm \
            --name rustscan rustscan/rustscan:2.1.1 \
            -a "$TARGET" -g -p "$WATCHED_PORT")

        if [ -n "$port_scan" ]; then
            echo "Port $WATCHED_PORT is open on $TARGET"
            service_discovery "$TARGET" "$WATCHED_PORT"
            send_telegram_message "\ud83d\udea8 Port $WATCHED_PORT is now open on $TARGET. Service details logged."
            break
        else
            echo "Port $WATCHED_PORT is not open yet. Sleeping for 5 seconds..."
            sleep 5
        fi
    done
}

# Combined Host Discovery and Port Monitoring
combined_mode() {
    echo "Starting combined host discovery and port monitoring"
    host_discovery
    monitor_port
}

# Main execution based on the mode
case $MODE in
p)
    monitor_port
    ;;
h)
    echo "Starting host discovery on $TARGET"
    host_discovery
    ;;
hp)
    combined_mode
    ;;
*)
    usage
    ;;
esac
