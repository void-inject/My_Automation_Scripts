#!/usr/bin/env bash

DEFAULT_PORT="80" # Default port to use if no port is provided.

# Function to write results to the banner file
# Parameters:
#   $1 - IP address
#   $2 - Content to write to the file
write_to_banner() {
    local ip="$1"
    local content="$2"
    printf "===================\n%s\n===================\n\n" "$content" >>"${ip}_banner.txt"
}

# Function to grab the HTTP Server header using curl
# Parameters:
#   $1 - IP address
#   $2 - Port
get_server_header() {
    local ip="$1"
    local port="$2"
    echo "Attempting to grab the Server header of ${ip}..." >>"${ip}_banner.txt"
    result=$(curl -s --head "http://${ip}:${port}" | grep Server | awk -F':' '{print $2}')

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Function to run netcat to fetch banners from the target
# Parameters:
#   $1 - IP address
#   $2 - Port
scan_with_netcat() {
    local ip="$1"
    local port="$2"
    echo "Running netcat on ${ip}:${port}" >>"${ip}_banner.txt"
    result=$(echo -e "\n" | nc -v "${ip}" -w 1 "${port}" 2>/dev/null)

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Function to run nmap and extract banners using the banner.nse script
# Parameters:
#   $1 - IP address
nmap_scan() {
    local ip="$1"
    echo "Running nmap on ${ip}" >>"${ip}_banner.txt"
    result=$(nmap -sV --script=banner.nse "${ip}" | grep "|_banner\||_http-server-header")

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Main script logic
# Prompt the user to select input mode: file or single IP
read -r -p "Would you like to use a file with IPs (y/n)? " use_file

if [[ "${use_file}" =~ ^[Yy]$ ]]; then
    # File mode: prompt for a file containing IP addresses
    read -r -p "Enter the file containing IP addresses: " file
    if [ ! -f "${file}" ]; then
        echo "File: ${file} was not found."
        exit 1
    fi

    # Prompt for port number (default is 80)
    read -r -p "Enter port (default: 80): " port
    port="${port:-$DEFAULT_PORT}"

    # Process each IP in the file
    while read -r ip; do
        [ -z "${ip}" ] && continue          # Skip empty lines
        nmap_scan "${ip}"                   # Run nmap scan
        scan_with_netcat "${ip}" "${port}"  # Run netcat
        get_server_header "${ip}" "${port}" # Grab HTTP Server header
    done <"${file}"
else
    # Single IP mode: prompt for target IP
    read -r -p "Type a target IP address: " ip
    if [ -z "${ip}" ]; then
        echo "You must provide an IP address."
        exit 1
    fi

    # Prompt for port number (default is 80)
    read -r -p "Type a target port (default: 80): " port
    port="${port:-$DEFAULT_PORT}"

    # Run scans on the single IP
    nmap_scan "${ip}"                   # Run nmap scan
    scan_with_netcat "${ip}" "${port}"  # Run netcat
    get_server_header "${ip}" "${port}" # Grab HTTP Server header
fi
#!/usr/bin/env bash

DEFAULT_PORT="80" # Default port to use if no port is provided.

# Function to write results to the banner file
# Parameters:
#   $1 - IP address
#   $2 - Content to write to the file
write_to_banner() {
    local ip="$1"
    local content="$2"
    printf "===================\n%s\n===================\n\n" "$content" >>"${ip}_banner.txt"
}

# Function to grab the HTTP Server header using curl
# Parameters:
#   $1 - IP address
#   $2 - Port
get_server_header() {
    local ip="$1"
    local port="$2"
    echo "Attempting to grab the Server header of ${ip}..." >>"${ip}_banner.txt"
    result=$(curl -s --head "http://${ip}:${port}" | grep Server | awk -F':' '{print $2}')

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Function to run netcat to fetch banners from the target
# Parameters:
#   $1 - IP address
#   $2 - Port
scan_with_netcat() {
    local ip="$1"
    local port="$2"
    echo "Running netcat on ${ip}:${port}" >>"${ip}_banner.txt"
    result=$(echo -e "\n" | nc -v "${ip}" -w 1 "${port}" 2>/dev/null)

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Function to run nmap and extract banners using the banner.nse script
# Parameters:
#   $1 - IP address
nmap_scan() {
    local ip="$1"
    echo "Running nmap on ${ip}" >>"${ip}_banner.txt"
    result=$(nmap -sV --script=banner.nse "${ip}" | grep "|_banner\||_http-server-header")

    if [ -n "${result}" ]; then
        write_to_banner "${ip}" "+ IP Address: ${ip}\n+ Banner: ${result}"
    fi
}

# Main script logic
# Prompt the user to select input mode: file or single IP
read -r -p "Would you like to use a file with IPs (y/n)? " use_file

if [[ "${use_file}" =~ ^[Yy]$ ]]; then
    # File mode: prompt for a file containing IP addresses
    read -r -p "Enter the file containing IP addresses: " file
    if [ ! -f "${file}" ]; then
        echo "File: ${file} was not found."
        exit 1
    fi

    # Prompt for port number (default is 80)
    read -r -p "Enter port (default: 80): " port
    port="${port:-$DEFAULT_PORT}"

    # Process each IP in the file
    while read -r ip; do
        [ -z "${ip}" ] && continue          # Skip empty lines
        nmap_scan "${ip}"                   # Run nmap scan
        scan_with_netcat "${ip}" "${port}"  # Run netcat
        get_server_header "${ip}" "${port}" # Grab HTTP Server header
    done <"${file}"
else
    # Single IP mode: prompt for target IP
    read -r -p "Type a target IP address: " ip
    if [ -z "${ip}" ]; then
        echo "You must provide an IP address."
        exit 1
    fi

    # Prompt for port number (default is 80)
    read -r -p "Type a target port (default: 80): " port
    port="${port:-$DEFAULT_PORT}"

    # Run scans on the single IP
    nmap_scan "${ip}"                   # Run nmap scan
    scan_with_netcat "${ip}" "${port}"  # Run netcat
    get_server_header "${ip}" "${port}" # Grab HTTP Server header
fi
