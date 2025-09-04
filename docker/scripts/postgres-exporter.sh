#!/bin/bash

# PostgreSQL Exporter Helper Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐘 PostgreSQL Exporter Management${NC}"

cleanup_orphans() {
    echo -e "${YELLOW}Cleaning up orphaned containers and networks...${NC}"
    cd "$DOCKER_DIR"

    # Stop and remove orphaned containers
    docker stop infra-grafana infra-prometheus infra-node-exporter infra-cadvisor 2>/dev/null || true
    docker rm infra-grafana infra-prometheus infra-node-exporter infra-cadvisor 2>/dev/null || true

    # Clean up networks
    docker network rm profiles_infra-network services_infra-network 2>/dev/null || true
    docker network prune -f

    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

case "${1:-help}" in
    start)
        echo -e "${GREEN}Starting PostgreSQL + PostgreSQL Exporter...${NC}"

        # Cleanup orphans first
        cleanup_orphans

        # Change to docker directory
        cd "$DOCKER_DIR"

        # Start PostgreSQL database first
        echo -e "${YELLOW}1. Starting PostgreSQL database...${NC}"
        docker-compose -f profiles/database.yml up -d postgresql

        # Wait for PostgreSQL to be ready
        echo -e "${YELLOW}2. Waiting for PostgreSQL to be ready...${NC}"
        sleep 15

        # Start postgres-exporter using the same network context
        echo -e "${YELLOW}3. Starting PostgreSQL Exporter...${NC}"
        docker-compose -f profiles/database.yml -f services/monitoring-exporters.yml up -d postgres-exporter

        echo -e "${GREEN}✅ PostgreSQL Exporter started successfully!${NC}"
        ;;

    start-with-database)
        echo -e "${GREEN}Starting complete database stack with monitoring...${NC}"

        # Cleanup orphans first
        cleanup_orphans

        cd "$DOCKER_DIR"

        # Start database stack and exporters together using multiple compose files
        echo -e "${YELLOW}Starting database + postgres-exporter...${NC}"
        docker-compose -f profiles/database.yml -f services/monitoring-exporters.yml up -d

        echo -e "${GREEN}✅ Database stack with monitoring started!${NC}"
        ;;

    cleanup)
        cleanup_orphans
        ;;

    stop)
        echo -e "${YELLOW}Stopping PostgreSQL Exporter...${NC}"
        docker stop infra-postgres-exporter 2>/dev/null || true
        docker rm infra-postgres-exporter 2>/dev/null || true
        echo -e "${GREEN}✅ PostgreSQL Exporter stopped${NC}"
        ;;

    status)
        echo -e "${BLUE}PostgreSQL Exporter Status:${NC}"
        if docker ps | grep -q infra-postgres-exporter; then
            echo -e "${GREEN}✅ Running${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep postgres-exporter
        else
            echo -e "${RED}❌ Not running${NC}"
        fi
        ;;

    logs)
        echo -e "${BLUE}PostgreSQL Exporter Logs:${NC}"
        docker logs infra-postgres-exporter --tail 50 -f
        ;;

    metrics)
        echo -e "${BLUE}Testing PostgreSQL Exporter Metrics:${NC}"
        if docker ps | grep -q infra-postgres-exporter; then
            echo -e "${GREEN}Fetching metrics...${NC}"
            docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics 2>/dev/null | head -20
            echo -e "${BLUE}... (showing first 20 lines)${NC}"
        else
            echo -e "${RED}❌ PostgreSQL Exporter is not running${NC}"
        fi
        ;;

    connect-test)
        echo -e "${BLUE}Testing PostgreSQL Connection:${NC}"
        if docker ps | grep -q infra-postgres-exporter; then
            echo -e "${YELLOW}Testing metrics endpoint...${NC}"
            if docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics 2>/dev/null | grep -q "pg_up"; then
                PG_UP=$(docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics 2>/dev/null | grep "pg_up" | head -1)
                echo -e "${GREEN}✅ Connection test: $PG_UP${NC}"
            else
                echo -e "${RED}❌ Connection test failed${NC}"
            fi
        else
            echo -e "${RED}❌ PostgreSQL Exporter is not running${NC}"
        fi
        ;;

    help|*)
        echo -e "${BLUE}Usage: $0 {start|start-with-database|cleanup|stop|status|logs|metrics|connect-test}${NC}"
        echo ""
        echo -e "${YELLOW}Commands:${NC}"
        echo "  start               - Start PostgreSQL + PostgreSQL Exporter (sequential)"
        echo "  start-with-database - Start database stack + exporters together"
        echo "  cleanup             - Clean up orphaned containers and networks"
        echo "  stop                - Stop PostgreSQL Exporter"
        echo "  status              - Check if PostgreSQL Exporter is running"
        echo "  logs                - View PostgreSQL Exporter logs"
        echo "  metrics             - Test metrics endpoint"
        echo "  connect-test        - Test database connection"
        echo ""
        echo -e "${YELLOW}Note:${NC} Use cleanup if you encounter network conflicts"
        ;;
esac
