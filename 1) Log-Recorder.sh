#!/usr/bin/env bash

# Generate a unique log filename using the current date and time in the format MM_DD_YYYY_HH:MM:SS.log
FILENAME=$(date +%m_%d_%Y_%H:%M:%S).log

# Ensure the directory ~/sessions exists to store log files
# If the directory doesn't exist, create it
if [ ! -d ~/sessions ]; then
    mkdir ~/sessions
fi

# Check if the SCRIPT environment variable is already set
# This ensures that a logging session isn't started multiple times
if [ -z "$SCRIPT" ]; then

    # Set the SCRIPT environment variable to the log file path in the ~/sessions directory
    export SCRIPT="${HOME}/sessions/${FILENAME}"

    # Start logging the terminal session using the `script` command
    # -q: Suppresses startup messages for clean logging
    # -f: Ensures that the log file is updated in real-time
    script -q -f "${SCRIPT}"
fi
