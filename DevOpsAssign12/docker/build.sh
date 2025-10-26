#!/bin/bash
# Docker build and test script

set -e

echo "Building Docker images..."

# Build web image
echo "Building Django web application image..."
docker build -t django-app:latest -f docker/web/Dockerfile django_app/

# Build database image
echo "Building PostgreSQL database image..."
docker build -t postgres-app:latest docker/db/

echo "Docker images built successfully!"

# List images
echo "Available images:"
docker images | grep -E "(django-app|postgres-app)"

echo "To test locally, run:"
echo "  docker-compose -f docker-compose.dev.yml up"
echo ""
echo "To deploy to Swarm, run:"
echo "  docker stack deploy -c docker-compose.yml myapp"