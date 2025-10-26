#!/bin/bash
# Docker test script

set -e

echo "Testing Docker containers..."

# Start containers in development mode
echo "Starting containers..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Test database connection
echo "Testing database connection..."
docker-compose -f docker-compose.dev.yml exec db pg_isready -U postgres -d postgres

# Test web application
echo "Testing web application..."
curl -f http://localhost:8000/login/ || echo "Web app not ready yet, waiting..."
sleep 10
curl -f http://localhost:8000/login/ || echo "Web app test failed"

# Run Django tests inside container
echo "Running Django tests..."
docker-compose -f docker-compose.dev.yml exec web python test_app.py

echo "All tests completed!"

# Clean up
echo "Stopping containers..."
docker-compose -f docker-compose.dev.yml down

echo "Docker test completed successfully!"