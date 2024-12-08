#!/usr/bin/env bash

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -g <subnet>   Generate IPs for a given subnet (e.g., 192.168.1)"
    echo "  -s <file>     Clean an existing file of IPs by removing unreachable IPs"
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

# Parse flags
while getopts "g:s:h" opt; do
    case $opt in
    g) SUBNET="${OPTARG}" ;;
    s) FILE="${OPTARG}" ;;
    h) show_help ;;
    *) show_help ;;
    esac
done

# Function to generate IPs
generate_ips() {
    local subnet=$1
    local output_file="${subnet//./-}-host.txt"

    # Clear the file (use true as a no-op to satisfy ShellCheck)
    true >"${output_file}"

    # Generate IPs
    for ip in $(seq 1 254); do
        echo "${subnet}.${ip}" >>"${output_file}"
    done

    echo "IP addresses from subnet ${subnet} saved to ${output_file}"
}

# Function to clean unreachable IPs
clean_ips() {
    local file=$1
    local temp_file="reachable_ips.tmp"

    if [[ ! -f "${file}" ]]; then
        echo "File '${file}' not found!"
        exit 1
    fi

    # Clear the temporary file (use true as a no-op to satisfy ShellCheck)
    true >"${temp_file}"

    # Ping each IP
    while IFS= read -r ip; do
        if ping -c 1 -W 1 "${ip}" &>/dev/null; then
            echo "${ip}" >>"${temp_file}"
        else
            echo "IP ${ip} is not reachable."
        fi
    done <"${file}"

    # Replace the original file
    mv "${temp_file}" "${file}"
    echo "Unavailable IPs removed. Updated file: ${file}"
}

# Execute based on flags
if [[ -n "${SUBNET}" ]]; then
    generate_ips "${SUBNET}"
fi

if [[ -n "${FILE}" ]]; then
    clean_ips "${FILE}"
fi
