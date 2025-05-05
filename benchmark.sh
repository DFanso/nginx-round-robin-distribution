#!/bin/bash

# Script for comparing web performance with and without load balancing
# using ApacheBench (ab)

echo "======================================================"
echo "Load Balancing Performance Test for BogdanLTD"
echo "======================================================"

# Make sure Apache Bench is installed
if ! [ -x "$(command -v ab)" ]; then
  echo "Error: Apache Bench (ab) is not installed."
  echo "Please install it using: apt-get install apache2-utils"
  exit 1
fi

# Constants
NUM_REQUESTS=1000
CONCURRENCY=(1 10 25 50 100)
OUTPUT_FILE="benchmark_results.txt"

# Clean previous results
echo "" > $OUTPUT_FILE
echo "Benchmark Results" >> $OUTPUT_FILE
echo "=====================================================" >> $OUTPUT_FILE
echo "Date: $(date)" >> $OUTPUT_FILE
echo "=====================================================" >> $OUTPUT_FILE

# Start containers if not already running
echo "Ensuring containers are running..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be available..."
sleep 10

# Get the IP of the load balancer
LB_IP=$(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_frontend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-nginx-lb-1)
echo "Load Balancer IP: $LB_IP"

# Get IPs of individual web servers
WEB1_IP=$(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_frontend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-web1-1)
WEB2_IP=$(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_frontend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-web2-1)
echo "Web Server 1 IP: $WEB1_IP"
echo "Web Server 2 IP: $WEB2_IP"

# Benchmark function
run_benchmark() {
    local url=$1
    local name=$2
    
    echo ""
    echo "Testing $name... ($url)"
    echo "" >> $OUTPUT_FILE
    echo "Testing $name ($url)" >> $OUTPUT_FILE
    echo "=====================================================" >> $OUTPUT_FILE
    
    for c in "${CONCURRENCY[@]}"; do
        echo "  Running benchmark with concurrency $c..."
        echo "Concurrency: $c" >> $OUTPUT_FILE
        ab -n $NUM_REQUESTS -c $c -S $url > temp_results.txt
        
        # Extract key metrics
        REQUESTS_PER_SEC=$(grep "Requests per second" temp_results.txt | awk '{print $4}')
        TIME_PER_REQ=$(grep "Time per request" temp_results.txt | head -1 | awk '{print $4}')
        FAILED_REQUESTS=$(grep "Failed requests" temp_results.txt | awk '{print $3}')
        
        echo "  Requests per second: $REQUESTS_PER_SEC" 
        echo "  Time per request: $TIME_PER_REQ ms"
        echo "  Failed requests: $FAILED_REQUESTS"
        
        echo "Requests per second: $REQUESTS_PER_SEC" >> $OUTPUT_FILE
        echo "Time per request: $TIME_PER_REQ ms" >> $OUTPUT_FILE
        echo "Failed requests: $FAILED_REQUESTS" >> $OUTPUT_FILE
        echo "--------------------------" >> $OUTPUT_FILE
    done
}

# Run benchmarks
echo "Starting benchmarks..."

# Test without load balancer (direct to web1)
run_benchmark "http://$WEB1_IP/" "Direct to Web Server 1 (No LB)"

# Test without load balancer (direct to web2)
run_benchmark "http://$WEB2_IP/" "Direct to Web Server 2 (No LB)"

# Test with load balancer
run_benchmark "http://$LB_IP/" "With Load Balancer"

echo ""
echo "Benchmarks completed. Results saved to $OUTPUT_FILE"
echo "======================================================"

# Display summary
echo ""
echo "Summary Report:"
echo "======================================================"
cat $OUTPUT_FILE

# Clean up temp file
rm -f temp_results.txt 