#!/bin/bash

# Docker Compose Helper Script untuk Stop Services
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo -e "${BLUE}Usage: $0 [PROFILE|SERVICE...] [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Profiles:${NC}"
    echo "  database   - Stop PostgreSQL + Redis"
    echo "  monitoring - Stop Prometheus + Grafana"
    echo "  full       - Stop all services"
    echo "  all        - Stop all running containers"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --volumes  - Remove volumes as well"
    echo "  --clean    - Remove containers, networks, and volumes"
}

stop_all() {
    echo -e "${YELLOW}Stopping all containers...${NC}"
    docker-compose -f "$DOCKER_DIR/base/docker-compose.yml" down
    docker stop $(docker ps -q) 2>/dev/null || true
}

stop_profile() {
    local profile=$1
    local profile_file="$DOCKER_DIR/profiles/${profile}.yml"

    if [[ ! -f "$profile_file" ]]; then
        echo -e "${RED}Error: Profile '$profile' not found${NC}"
        exit 1
    fi

    echo -e "${GREEN}Stopping profile: $profile${NC}"
    docker-compose -f "$profile_file" down
}

# Parse arguments
REMOVE_VOLUMES=false
CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        all)
            stop_all
            if [[ "$CLEAN" == true ]]; then
                echo -e "${YELLOW}Cleaning up volumes and networks...${NC}"
                docker system prune -f
                docker volume prune -f
            fi
            exit 0
            ;;
        database|monitoring|full)
            stop_profile "$1"
            exit 0
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option or profile '$1'${NC}"
            usage
            exit 1
            ;;
    esac
done

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

echo -e "${GREEN}✅ Services stopped successfully!${NC}"
