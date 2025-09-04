#!/bin/bash

# Docker Compose Helper Script untuk Start Services
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"
BASE_COMPOSE="$DOCKER_DIR/base/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo -e "${BLUE}Usage: $0 [PROFILE|SERVICE...]${NC}"
    echo ""
    echo -e "${YELLOW}Profiles:${NC}"
    echo "  database   - PostgreSQL + Redis"
    echo "  monitoring - Prometheus + Grafana"
    echo "  full       - All services"
    echo ""
    echo -e "${YELLOW}Individual Services:${NC}"
    echo "  postgresql - PostgreSQL database"
    echo "  redis      - Redis cache"
    echo "  prometheus - Prometheus monitoring"
    echo "  grafana    - Grafana dashboard"
    echo "  nginx      - NGINX reverse proxy"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 database"
    echo "  $0 postgresql redis"
    echo "  $0 monitoring"
    echo "  $0 full"
}

start_profile() {
    local profile=$1
    local profile_file="$DOCKER_DIR/profiles/${profile}.yml"

    if [[ ! -f "$profile_file" ]]; then
        echo -e "${RED}Error: Profile '$profile' not found${NC}"
        exit 1
    fi

    echo -e "${GREEN}Starting profile: $profile${NC}"
    # Change to docker directory untuk path relatif yang benar
    cd "$DOCKER_DIR"
    docker-compose -f "profiles/${profile}.yml" up -d
}

start_services() {
    local services=("$@")
    local compose_files=("-f" "$BASE_COMPOSE")

    for service in "${services[@]}"; do
        local service_file="$DOCKER_DIR/services/${service}.yml"
        if [[ ! -f "$service_file" ]]; then
            echo -e "${RED}Error: Service '$service' not found${NC}"
            exit 1
        fi
        compose_files+=("-f" "$service_file")
    done

    echo -e "${GREEN}Starting services: ${services[*]}${NC}"
    docker-compose "${compose_files[@]}" up -d
}

# Main logic
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

# Check if first argument is a profile
if [[ $# -eq 1 ]]; then
    case $1 in
        database|monitoring|full)
            start_profile "$1"
            exit 0
            ;;
        postgresql|redis|prometheus|grafana|nginx)
            start_services "$1"
            exit 0
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown profile or service '$1'${NC}"
            usage
            exit 1
            ;;
    esac
else
    # Multiple services
    start_services "$@"
fi

echo -e "${GREEN}✅ Services started successfully!${NC}"
echo -e "${BLUE}Check status with: docker-compose ps${NC}"
