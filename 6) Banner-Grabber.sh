#!/usr/bin/env bash

DEFAULT_PORT="80"

# Function to write results to the banner file
write_to_banner() {
    local ip="$1"
    local content="$2"
    echo "===================" >>"${ip}_banner.txt"
    echo "$content" >>"${ip}_banner.txt"
    echo "===================" >>"${ip}_banner.txt"
    echo >>"${ip}_banner.txt"
}

# Function to grab server header using curl
get_server_header() {
    local ip="$1"
    local port="$2"
    echo "Attempting to grab the Server header of ${ip}..." >>"${ip}_banner.txt"
    result=$(curl -s --head "${ip}:${port}" | grep Server | awk -F':' '{print $2}')

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Function to run netcat on IP addresses from file or single IP
scan_with_netcat() {
    local ip="$1"
    local port="$2"
    echo "Running netcat on ${ip}:${port}" >>"${ip}_banner.txt"
    result=$(echo -e "\n" | nc -v "${ip}" -w 1 "${port}" 2>/dev/null)

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Main script logic
read -r -p "Would you like to use a file with IPs (y/n)? " use_file

if [ "${use_file}" =~ ^[Yy]$ ]; then
    read -r -p "Enter the file containing IP addresses: " file
    if [ ! -f "${file}" ]; then
        echo "File: ${file} was not found."
        exit 1
    fi

    read -r -p "Enter port (default: 80): " port
    port="${port:-$DEFAULT_PORT}"

    # Run both netcat and curl for IPs in the file
    while read -r ip; do
        scan_with_netcat "${ip}" "${port}"
        get_server_header "${ip}" "${port}"
    done <"${file}"
else
    read -r -p "Type a target IP address: " ip
    if [ -z "${ip}" ]; then
        echo "You must provide an IP address."
        exit 1
    fi

    read -r -p "Type a target port (default: 80): " port
    port="${port:-$DEFAULT_PORT}"

    # Run both Netcat and Curl for the single IP
    scan_with_netcat "${ip}" "${port}"
    get_server_header "${ip}" "${port}"
fi
