#!/usr/bin/env bash

# Input argument:
TARGET=$1 # The base subnet (e.g., 192.168.1)

# Ensure the input argument is provided
if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <TARGET_SUBNET>"
    exit 1
fi

# Define the output file name based on the target subnet
OUTPUT_FILE="${TARGET//./-}-host.txt" # Replace dots with hyphens for the file name

# Generate IP addresses for the target subnet and save them to the output file
for ip in $(seq 1 254); do

    # Construct the full IP address and append it to the output file
    echo "${TARGET}.${ip}" >>"$OUTPUT_FILE"

done

# Print a success message
echo "IP addresses from subnet ${TARGET} saved to ${OUTPUT_FILE}"
