#!/usr/bin/env bash

# Check if a file is provided as an argument
if [[ -z "$1" ]]; then
    echo "Usage: $0 <file_with_ips>"
    exit 1
fi

# File containing the list of IPs
IP_FILE="$1"

# Check if the IP file exists
if [[ ! -f "${IP_FILE}" ]]; then
    echo "File '${IP_FILE}' not found!"
    exit 1
fi

# Temporary file for reachable IPs
TEMP_FILE="reachable_ips.tmp"

touch ${TEMP_FILE}

# Read each IP and check connectivity
while IFS= read -r ip; do

    if ping -c 1 -W 1 "${ip}" &>/dev/null; then
        echo "${ip}" >>"${TEMP_FILE}"
    else
        echo "IP ${ip} is not reachable."
    fi

done <"${IP_FILE}"

rm "${IP_FILE}"

# Replace the original file with the reachable IPs
mv "${TEMP_FILE}" "${IP_FILE}"

echo "Unavailable IPs removed. Updated file: $IP_FILE"
