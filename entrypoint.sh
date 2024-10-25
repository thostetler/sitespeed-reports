#!/bin/bash

# Validate input for test name
if [ -z "$1" ]; then
  echo "Usage: $0 <test-name>"
  exit 1
fi

# Set variables, allowing dynamic input for paths and other configurations
TEST_NAME=$1
RUNS=${RUNS:-5}
URLS_DIR=${URLS_DIR:-"/sitespeed.io/urls"}  # Default location inside container
LATENCY=${LATENCY:-100}

# Map test names to their corresponding URL file dynamically
URL_FILE="$URLS_DIR/$TEST_NAME.txt"

# Check if the URL file exists
if [ ! -f "$URL_FILE" ]; then
  echo "URL file for $TEST_NAME not found at $URL_FILE"
  exit 1
fi

echo "Whoami? $(whoami) $(id -u)"
echo "Running: /start.sh --cpu -n $RUNS -b chrome --latency $LATENCY $URL_FILE"

# Run sitespeed.io with dynamic arguments inside the container
/start.sh --cpu -n $RUNS -b chrome --latency $LATENCY $URL_FILE
