#!/usr/bin/env bash

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -g <subnet>   Generate IPs for a given subnet (e.g., 192.168.1)"
    echo "  -s <file>     Clean an existing file of IPs by removing unreachable IPs"
    echo "  -f <file>     Sort IPs from a file by open ports"
    echo "  -h            Show this help message and exit"
    exit 0
}

# Check if no arguments are passed
if [[ $# -eq 0 ]]; then
    show_help
fi

# Initialize variables
SUBNET=""
FILE=""
FILTER=""

# Parse flags
while getopts "g:s:f:h" opt; do
    case $opt in
    g) SUBNET="${OPTARG}" ;;
    s) FILE="${OPTARG}" ;;
    f) FILTER="${OPTARG}" ;;
    h) show_help ;;
    *) show_help ;;
    esac
done

# Function to generate IPs
generate_ips() {
    local subnet=$1
    local output_file="${subnet//./-}-host.txt"

    # Clear the file
    : >"${output_file}"

    # Generate IPs from 1 to 254
    for ip in $(seq 1 254); do
        echo "${subnet}.${ip}" >>"${output_file}"
    done

    echo "IP addresses from subnet ${subnet} saved to ${output_file}"
}

# Function to clean unreachable IPs
clean_ips() {
    local file=$1
    local temp_file="reachable_ips.tmp"

    if [ ! -f "${file}" ]; then
        echo "File '${file}' not found!"
        exit 1
    fi

    # Clear the temporary file
    : >"${temp_file}"

    # Ping each IP and keep reachable ones
    while IFS= read -r ip; do
        if ping -c 1 -W 1 "${ip}" &>/dev/null; then
            echo "${ip}" >>"${temp_file}"
        fi
    done <"${file}"

    # Replace the original file with the updated list
    mv "${temp_file}" "${file}"
    echo "Unavailable IPs removed. Updated file: ${file}"
}

# Function to sort IPs by open ports using nmap
sort_ips() {
    local file=$1
    local result

    if [ ! -f "${file}" ]; then
        echo "File '${file}' not found!"
        exit 1
    fi

    result=$(nmap -iL "${file}" --open)

    # Parse nmap results
    while IFS= read -r line; do
        if echo "${line}" | grep -q "Nmap scan report"; then
            ip=$(echo "${line}" | awk -F'for ' '{print $2}')
        elif echo "${line}" | grep -q "tcp open"; then
            port=$(echo "${line}" | awk -F'/' '{print $1}')
            file="port-${port}.txt"
            echo "${ip}" >>"${file}"
        fi
    done <<<"${result}"

    echo "IP sorting by ports completed."
}

# Execute based on flags
if [ -n "${SUBNET}" ]; then
    generate_ips "${SUBNET}"
fi

if [ -n "${FILE}" ]; then
    clean_ips "${FILE}"
fi

if [ -n "${FILTER}" ]; then
    sort_ips "${FILTER}"
fi
