#!/bin/bash

# Set variables for configuration with default values
RUNS=${RUNS:-5}
URLS_DIR=${URLS_DIR:-"./urls"}  # Default directory for URL files
LATENCY=${LATENCY:-100}

# Check if a specific test name was provided as an argument
if [ -z "$1" ]; then
  echo "No specific test name provided. Running all tests in the '$URLS_DIR' directory."

  # Ensure the directory exists
  if [ ! -d "$URLS_DIR" ]; then
    echo "URLs directory '$URLS_DIR' does not exist. Exiting."
    exit 1
  fi

  # Loop through each .txt file in the directory and run the test
  for URL_FILE in "$URLS_DIR"/*.txt; do
    TEST_NAME=$(basename "$URL_FILE" .txt)
    echo "Running test for '$TEST_NAME' with URL file: $URL_FILE"

    # Run the Docker command for each test
    docker run --cap-add=NET_ADMIN --shm-size=2g --rm -v "$(pwd):/sitespeed.io" --network=host \
      -e MAX_OLD_SPACE_SIZE=4096 \
      sitespeedio/sitespeed.io:latest \
      --cpu -n "$RUNS" -b chrome --latency "$LATENCY" "$URL_FILE"
  done

else
  # If a test name is provided, use it to find the corresponding URL file
  TEST_NAME=$1
  URL_FILE="$URLS_DIR/$TEST_NAME.txt"

  # Verify that the specified URL file exists
  if [ ! -f "$URL_FILE" ]; then
    echo "URL file for '$TEST_NAME' not found at '$URL_FILE'. Exiting."
    exit 1
  fi

  # Inform the user about the test being run
  echo "Running test for '$TEST_NAME' with URL file: $URL_FILE"

  # Run the Docker command for the specified test
  docker run --cap-add=NET_ADMIN --shm-size=2g --rm -v "$(pwd):/sitespeed.io" --network=host \
    -e MAX_OLD_SPACE_SIZE=4096 \
    sitespeedio/sitespeed.io:latest \
    --filmstrip.showAll \
    --cpu -n "$RUNS" -b chrome --latency "$LATENCY" "$URL_FILE"
fi
