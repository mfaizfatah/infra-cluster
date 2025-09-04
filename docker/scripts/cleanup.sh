#!/bin/bash

# Docker Cleanup Helper Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Cleaning up Docker containers and resources...${NC}"

# Stop all running containers
echo -e "${BLUE}Stopping all containers...${NC}"
docker stop $(docker ps -q) 2>/dev/null || echo "No running containers to stop"

# Remove all containers
echo -e "${BLUE}Removing all containers...${NC}"
docker container prune -f

# Remove unused networks
echo -e "${BLUE}Removing unused networks...${NC}"
docker network prune -f

# Remove unused volumes (optional - uncomment if needed)
# echo -e "${BLUE}Removing unused volumes...${NC}"
# docker volume prune -f

# Remove unused images (optional - uncomment if needed)
# echo -e "${BLUE}Removing unused images...${NC}"
# docker image prune -f

echo -e "${GREEN}✅ Docker cleanup completed!${NC}"
echo -e "${BLUE}You can now try starting services again.${NC}"
