#!/bin/bash

# BogdanLTD Nginx Load Balancer Setup and Testing Script
# This script automates the entire process of setting up and testing 
# nginx load balancing with Docker containers

echo "======================================================"
echo "BogdanLTD Nginx Load Balancer Setup"
echo "======================================================"

# Check if Docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed."
  echo "Please install Docker before running this script."
  exit 1
fi

# Check if Docker Compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "Error: Docker Compose is not installed."
  echo "Please install Docker Compose before running this script."
  exit 1
fi

# Step 1: Build and Start Docker containers
echo "Step 1: Building and starting Docker containers..."
docker-compose build
docker-compose up -d

# Step 2: Verify that all containers are running
echo "Step 2: Verifying all containers are running..."
docker ps
echo ""
echo "Waiting for all services to be fully operational..."
sleep 10

# Step 3: Display container IPs for direct access
echo "Step 3: Displaying container IPs for direct access..."
# Get container IPs properly from the first network interface
echo "Load Balancer IP: $(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_frontend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-nginx-lb-1)"
echo "Web Server 1 IP: $(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_frontend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-web1-1)"
echo "Web Server 2 IP: $(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_frontend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-web2-1)"
echo "PHP Server 1 IP: $(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_backend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-php1-1)"
echo "PHP Server 2 IP: $(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_backend"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-php2-1)"
echo "Database IP: $(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nginx-round-robin-distribution_database"}}{{$value.IPAddress}}{{end}}{{end}}' nginx-round-robin-distribution-db-1)"

# Step 4: Make test scripts executable
echo "Step 4: Making test scripts executable..."
chmod +x benchmark.sh test-load-balancing.sh

# Step 5: Run performance tests
echo "Step 5: Running performance tests..."
# Check if ApacheBench is installed before running benchmark
if [ -x "$(command -v ab)" ]; then
  echo "Running ApacheBench tests..."
  ./benchmark.sh
else
  echo "Warning: ApacheBench (ab) is not installed. Running alternative test..."
  echo "To install ApacheBench on Ubuntu/Debian: sudo apt-get install apache2-utils"
  echo ""
  # Run the alternative test that uses curl
  ./test-load-balancing.sh
fi

# Step 6: Display container logs to verify load balancing
echo "Step 6: Displaying container logs to verify load balancing..."
echo "Load Balancer logs:"
docker logs nginx-round-robin-distribution-nginx-lb-1
echo ""
echo "Web Server 1 logs:"
docker logs nginx-round-robin-distribution-web1-1
echo ""
echo "Web Server 2 logs:"
docker logs nginx-round-robin-distribution-web2-1

echo ""
echo "======================================================"
echo "Setup and testing completed successfully!"
echo "You can now access the load-balanced application at http://localhost"
echo "======================================================" 