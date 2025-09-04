#!/bin/bash

# Docker Compose Helper Script untuk View Logs
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
    echo -e "${BLUE}Usage: $0 [SERVICE] [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    echo "  postgresql - PostgreSQL database logs"
    echo "  redis      - Redis cache logs"
    echo "  prometheus - Prometheus monitoring logs"
    echo "  grafana    - Grafana dashboard logs"
    echo "  nginx      - NGINX proxy logs"
    echo "  all        - All services logs"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -f, --follow  - Follow log output"
    echo "  -t, --tail N  - Show last N lines (default: 100)"
    echo "  --since TIME  - Show logs since timestamp"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 postgresql -f"
    echo "  $0 all --tail 50"
    echo "  $0 grafana --since 1h"
}

show_logs() {
    local service=$1
    shift
    local options=("$@")

    if [[ "$service" == "all" ]]; then
        echo -e "${GREEN}Showing logs for all services...${NC}"
        docker-compose -f "$DOCKER_DIR/base/docker-compose.yml" logs "${options[@]}"
    else
        echo -e "${GREEN}Showing logs for: $service${NC}"
        docker logs "infra-$service" "${options[@]}"
    fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

SERVICE=$1
shift

# Convert arguments for docker logs
DOCKER_OPTIONS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            DOCKER_OPTIONS+=("--follow")
            shift
            ;;
        -t|--tail)
            DOCKER_OPTIONS+=("--tail" "$2")
            shift 2
            ;;
        --since)
            DOCKER_OPTIONS+=("--since" "$2")
            shift 2
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            usage
            exit 1
            ;;
    esac
done

# Default tail if no options specified
if [[ ${#DOCKER_OPTIONS[@]} -eq 0 ]]; then
    DOCKER_OPTIONS=("--tail" "100")
fi

show_logs "$SERVICE" "${DOCKER_OPTIONS[@]}"
