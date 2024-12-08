#!/usr/bin/env bash

# Static Configuration for Telegram Bot
BOT_TOKEN="<YOUR_BOT_TOKEN>" # Replace with your bot's token
CHAT_ID="<YOUR_CHAT_ID>"     # Replace with your chat ID

# Function to display usage instructions
usage() {
    echo "Usage: $0 <TARGET> <KNOWN_HOSTS_FILE> <INTERFACE>"
    echo "Example: $0 192.168.1.0/24 192-168-1-host.txt eth0"
    echo
    echo "Arguments:"
    echo "  TARGET           The target subnet for ARP scan (e.g., 192.168.1.0/24)"
    echo "  KNOWN_HOSTS_FILE Path to the file containing known host IPs"
    echo "  INTERFACE        Network interface to use (e.g., eth0)"
    exit 1
}

# Check for required arguments
if [[ $# -lt 3 ]]; then
    echo "Error: Insufficient arguments provided."
    usage
fi

# Input Arguments
TARGET=$1     # Network to scan (e.g., 192.168.1.0/24)
KNOWN_HOST=$2 # File containing a list of known hosts (IPs)
INTERFACE=$3  # Network interface to use for the ARP scan

# Derive NEW_HOSTS file name from KNOWN_HOSTS
NEW_HOST="${KNOWN_HOST/host/new}"

# Initialize counters
i=0 # Scan counter
k=0 # New host counter per scan

# Ensure the NEW_HOSTS file exists and is writable
if [ ! -w "${NEW_HOST}" ]; then
    touch "${NEW_HOST}" || {
        echo "Failed to create ${NEW_HOST}"
        exit 1
    }
fi

# Function to send a message via Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${message}" >/dev/null
}

# Main loop for periodic ARP scans
while true; do

    # Increment scan counter and display a message
    echo "Performing ARP scan #${i} against ${TARGET}"
    ((i++))

    # Perform ARP scan using the specified network interface and target
    sudo arp-scan -x -I "${INTERFACE}" "${TARGET}" | while read -r line; do
        # Extract the IP address of the host from the scan output
        host=$(echo "${line}" | awk '{print $1}')

        # Check if the host is already in the known hosts file
        if ! grep -q "${host}" "${KNOWN_HOST}"; then
            # Increment new host counter
            ((k++))

            # Log the new host with a timestamp
            DATE=$(date '+%H:%M %d/%m/%Y') # Current timestamp
            echo "Found a new host: ${host}!"
            echo "${i}.${k}: ${host} at ${DATE}" >>"${NEW_HOST}"

            # Send a Telegram notification
            send_telegram_message "🚨 New host detected: ${host} at ${DATE}"
        fi
    done

    # Display a message if no new hosts were detected
    echo "No new hosts detected in this scan."

    # Sleep for a random time (10-30 minutes) before the next scan
    sleep_time=$((RANDOM % 20 + 10))
    echo "Sleeping for ${sleep_time} minutes..."
    sleep $((sleep_time * 60))
done
