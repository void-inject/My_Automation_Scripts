#!/usr/bin/env bash

HOSTS_FILE=$1
RESULT=$(nmap -iL ${HOSTS_FILE} --open | grep "Nmap scan report\|tcp open")

# Read the nmap output line by line.
while read -r line; do

    if echo "${line}" | grep -q "report for"; then
        ip=$(echo "${line}" | awk -F'for ' '{print $2}')
    else
        port=$(echo "${line}" | grep open | awk -F'/' '{print $1}')
        file="port-${port}.txt"
        echo "${ip}" >>"${file}"
    fi

done <<<"${RESULT}"
