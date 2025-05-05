# Nginx Round-Robin Load Balancer

This project demonstrates the use of Nginx as a load balancer for BogdanLTD mobile phone store web services. It uses Docker and Docker Compose to create a testing environment with one Nginx load balancer, two backend Nginx web servers, two PHP servers, and one MySQL database server.

## Architecture

```
                       ┌─────────────┐
                       │             │
                       │  Nginx LB   │
                       │             │
                       └──────┬──────┘
                              │
                  ┌───────────┴───────────┐
                  │                       │
           ┌──────▼─────┐         ┌──────▼─────┐
           │             │         │             │
           │  Web Srv 1  │         │  Web Srv 2  │
           │   (Nginx)   │         │   (Nginx)   │
           │             │         │             │
           └──────┬──────┘         └──────┬──────┘
                  │                       │
       ┌──────────┴──────────┐   ┌────────┴────────┐
       │                     │   │                  │
┌──────▼─────┐       ┌──────▼─────┐        ┌──────▼──────┐
│             │       │             │       │              │
│  PHP Srv 1  │       │  PHP Srv 2  │       │  MySQL DB    │
│             │       │             │       │              │
└─────────────┘       └─────────────┘       └──────────────┘
```

## Prerequisites

- Docker 
- Docker Compose
- ApacheBench (ab) for performance testing

## Setup and Run

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/nginx-round-robin-distribution.git
   cd nginx-round-robin-distribution
   ```

2. Run the setup script to build and start all containers, and run benchmark tests:
   ```
   ./setup.sh
   ```

3. Alternatively, you can manually build and start the containers:
   ```
   docker-compose build
   docker-compose up -d
   ```

4. Access the web application:
   - Main application: http://localhost
   - Direct access to web servers (inside Docker network)

5. To run benchmarks:
   ```
   ./benchmark.sh
   ```

## Project Structure

- `docker-compose.yml` - Defines all services and their relationships
- `nginx-lb/` - Nginx load balancer configuration
- `web/` - Backend Nginx web server configuration
- `php/` - PHP-FPM server configuration
- `benchmark.sh` - Script to test performance with and without load balancing
- `setup.sh` - Main setup and testing script

## Performance Testing

The project includes two methods for testing load balancing performance:

1. **ApacheBench (ab)** - Used by the benchmark.sh script for detailed performance metrics with different concurrency levels to compare:
   - Direct access to Web Server 1 (no load balancing)
   - Direct access to Web Server 2 (no load balancing)
   - Access through the load balancer
   
   Results are saved to benchmark_results.txt

2. **Simple curl-based testing** - For environments without ApacheBench, the test-load-balancing.sh script offers an alternative:
   ```
   ./test-load-balancing.sh
   ```
   This script sends multiple requests and shows which backend server is currently handling each request, clearly demonstrating the round-robin distribution. It displays:
   - Currently serving server name and IP
   - Distribution statistics
   - Percentage of requests handled by each server

The setup.sh script will automatically use the appropriate testing method based on what's available in your environment.

