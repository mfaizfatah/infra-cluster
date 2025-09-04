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

case "${1:-help}" in
    start)
        echo -e "${GREEN}Starting PostgreSQL + PostgreSQL Exporter...${NC}"

        # Change to docker directory
        cd "$DOCKER_DIR"

        # Start PostgreSQL database first
        echo -e "${YELLOW}1. Starting PostgreSQL database...${NC}"
        docker-compose -f profiles/database.yml up -d postgresql

        # Wait for PostgreSQL to be ready
        echo -e "${YELLOW}2. Waiting for PostgreSQL to be ready...${NC}"
        sleep 10

        # Start postgres-exporter
        echo -e "${YELLOW}3. Starting PostgreSQL Exporter...${NC}"
        docker-compose -f base/docker-compose.yml -f services/monitoring-exporters.yml up -d postgres-exporter

        echo -e "${GREEN}✅ PostgreSQL Exporter started successfully!${NC}"
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
            docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics | head -20
            echo -e "${BLUE}... (showing first 20 lines)${NC}"
        else
            echo -e "${RED}❌ PostgreSQL Exporter is not running${NC}"
        fi
        ;;

    connect-test)
        echo -e "${BLUE}Testing PostgreSQL Connection:${NC}"
        if docker ps | grep -q infra-postgresql; then
            docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics | grep -E "(pg_up|pg_database_size_bytes)" || echo "Connection issue detected"
        else
            echo -e "${RED}❌ PostgreSQL database is not running${NC}"
        fi
        ;;

    help|*)
        echo -e "${BLUE}Usage: $0 {start|stop|status|logs|metrics|connect-test}${NC}"
        echo ""
        echo -e "${YELLOW}Commands:${NC}"
        echo "  start        - Start PostgreSQL + PostgreSQL Exporter"
        echo "  stop         - Stop PostgreSQL Exporter"
        echo "  status       - Check if PostgreSQL Exporter is running"
        echo "  logs         - View PostgreSQL Exporter logs"
        echo "  metrics      - Test metrics endpoint"
        echo "  connect-test - Test database connection"
        ;;
esac
