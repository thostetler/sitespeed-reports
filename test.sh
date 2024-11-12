#!/bin/bash

# Set variables for configuration with default values
RUNS=${RUNS:-5}
SITES_FILE=${SITES_FILE:-"./sites.yaml"}  # Default YAML file for sites
LATENCY=${LATENCY:-100}

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  echo "yq could not be found. Please install yq to proceed."
  exit 1
fi

# Function to run the test for a given site
run_test() {
  local TEST_NAME=$1
  local URL=$2
  local COOKIES=$3

  echo "Running test for '$TEST_NAME' with URL: $URL"

  # Run the Docker command for the test
  if [ -z "$COOKIES" ]; then
    docker run --cap-add=NET_ADMIN --shm-size=2g --rm -v "$(pwd):/sitespeed.io" --network=host \
      -e MAX_OLD_SPACE_SIZE=4096 \
      sitespeedio/sitespeed.io:latest \
      --cpu -n "$RUNS" -b chrome --latency "$LATENCY" "$URL"
  else
    docker run --cap-add=NET_ADMIN --shm-size=2g --rm -v "$(pwd):/sitespeed.io" --network=host \
      -e MAX_OLD_SPACE_SIZE=4096 \
      sitespeedio/sitespeed.io:latest \
      --cpu -n "$RUNS" -b chrome --latency "$LATENCY" --cookie "$COOKIES" "$URL"
  fi
}

# Check if a specific test name was provided as an argument
if [ -z "$1" ]; then
  echo "No specific test name provided. Running all tests in the '$SITES_FILE' file."

  # Loop through each site in the YAML file and run the test
  yq e '.sites | keys' "$SITES_FILE" | while read -r TEST_NAME; do
    URL=$(yq e ".sites.$TEST_NAME.urls[0]" "$SITES_FILE")
    COOKIES=$(yq e ".sites.$TEST_NAME.headers.cookies // empty" "$SITES_FILE")
    run_test "$TEST_NAME" "$URL" "$COOKIES"
  done

else
  # If a test name is provided, use it to find the corresponding URL and cookies
  TEST_NAME=$1
  URL=$(yq e ".sites.$TEST_NAME.urls[0]" "$SITES_FILE")

  # Verify that the specified URL exists
  if [ -z "$URL" ]; then
    echo "URL for '$TEST_NAME' not found in '$SITES_FILE'. Exiting."
    exit 1
  fi

  COOKIES=$(yq e ".sites.$TEST_NAME.headers.cookies // empty" "$SITES_FILE")
  run_test "$TEST_NAME" "$URL" "$COOKIES"
fi