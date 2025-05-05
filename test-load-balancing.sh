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

# Function to extract server information from response
get_server_info() {
  local response_file=$1
  
  # Extract server details
  local server_name=$(grep -o "Server Name:[^<]*" $response_file | awk -F ">" '{print $2}')
  local server_ip=$(grep -o "Server IP:[^<]*" $response_file | awk -F ">" '{print $2}')
  local client_ip=$(grep -o "Client IP:[^<]*" $response_file | awk -F ">" '{print $2}')
  local php_version=$(grep -o "PHP Version:[^<]*" $response_file | awk -F ">" '{print $2}')
  
  echo "   Currently serving server: $server_name ($server_ip)"
  echo "   Client IP: $client_ip"
  echo "   PHP Version: $php_version"
  
  # Return the server name for tracking distribution
  echo "$server_name"
}

# Array to store server names
declare -a SERVERS

echo ""
echo "Making $NUM_REQUESTS requests to test load balancing..."
echo ""

for ((i=1; i<=$NUM_REQUESTS; i++)); do
  echo "Request $i: "
  
  # Save response to temp file
  curl -s "$TEST_URL" > temp_response.html
  
  # Get server info from response
  SERVER=$(get_server_info "temp_response.html")
  
  # Store server name for distribution counting
  SERVERS[$i]=$SERVER
  
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