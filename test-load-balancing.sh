#!/bin/bash

# Simple script to test load balancing without ApacheBench
# Uses curl to make multiple requests and checks if different servers respond

echo "======================================================"
echo "Testing Load Balancing for BogdanLTD"
echo "======================================================"

# Number of requests to make
NUM_REQUESTS=10

# Get the IP of the load balancer
LB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-round-robin-distribution-nginx-lb-1)
echo "Load Balancer IP: $LB_IP"

# Make sure curl is available
if ! [ -x "$(command -v curl)" ]; then
  echo "Error: curl is not installed."
  echo "Please install curl to run this test."
  exit 1
fi

# If we can access localhost, use that instead of container IP
# This is better for Windows environments
if curl -s --head http://localhost > /dev/null; then
  TEST_URL="http://localhost"
  echo "Using localhost URL for testing"
else
  TEST_URL="http://$LB_IP"
  echo "Using container IP for testing: $TEST_URL"
fi

# Array to store server names
declare -a SERVERS

echo ""
echo "Making $NUM_REQUESTS requests to test load balancing..."
echo ""

for ((i=1; i<=$NUM_REQUESTS; i++)); do
  echo "Request $i: "
  
  # Save response to temp file
  curl -s "$TEST_URL" > temp_response.html
  
  # Extract server details directly from HTML
  SERVER_NAME=$(grep -o '<p><strong>Server Name:</strong> [^<]*' temp_response.html | cut -d'>' -f3 | cut -d' ' -f2-)
  SERVER_IP=$(grep -o '<p><strong>Server IP:</strong> [^<]*' temp_response.html | cut -d'>' -f3 | cut -d' ' -f2-)
  CLIENT_IP=$(grep -o '<p><strong>Client IP:</strong> [^<]*' temp_response.html | cut -d'>' -f3 | cut -d' ' -f2-)
  PHP_VERSION=$(grep -o '<p><strong>PHP Version:</strong> [^<]*' temp_response.html | cut -d'>' -f3 | cut -d' ' -f2-)
  
  echo "   Currently serving server: $SERVER_NAME ($SERVER_IP)"
  echo "   Client IP: $CLIENT_IP"
  echo "   PHP Version: $PHP_VERSION"
  
  # Store server name for distribution counting
  SERVERS[$i]=$SERVER_NAME
  
  # Add a visual separator
  echo "   ----------------------------------"
  
  # Add a small delay
  sleep 1
done

# Clean up
rm -f temp_response.html

echo ""
echo "Summary of servers used:"
echo "-----------------------------------------------------"

# Count occurrences of each server
declare -A SERVER_COUNTS
for server in "${SERVERS[@]}"; do
  if [[ -n "$server" ]]; then
    ((SERVER_COUNTS["$server"]++))
  fi
done

# Print server distribution
for server in "${!SERVER_COUNTS[@]}"; do
  echo "$server: ${SERVER_COUNTS["$server"]} requests"
done

# Calculate distribution percentage
total=${#SERVERS[@]}
if [[ $total -gt 0 ]]; then
  echo ""
  echo "Load distribution:"
  for server in "${!SERVER_COUNTS[@]}"; do
    percentage=$(( ${SERVER_COUNTS["$server"]} * 100 / $total ))
    echo "$server: $percentage%"
  done
fi

echo ""
echo "If you see requests distributed across multiple servers,"
echo "then the load balancing is working correctly!"
echo "=======================================================" 