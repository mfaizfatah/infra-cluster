#!/bin/bash

# Quick fix script untuk mengatasi Docker mounting issues
set -e

echo "🔧 Fixing Docker Compose mounting issues..."

# Stop dan remove semua container yang error
echo "🛑 Stopping and removing failed containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove orphaned networks
echo "🌐 Cleaning up networks..."
docker network prune -f

# Clear Docker Compose cache
echo "🧹 Clearing Docker Compose cache..."
docker system prune -f

echo "✅ Cleanup completed!"
echo ""
echo "Now testing if config files exist..."

# Check if config files exist
CONFIG_DIR="/home/mfaizfatah-nlite/infra-cluster/docker/config"
echo "📁 Checking config directory: $CONFIG_DIR"

if [ -f "$CONFIG_DIR/prometheus.yml" ]; then
    echo "✅ prometheus.yml found"
else
    echo "❌ prometheus.yml NOT found"
fi

if [ -f "$CONFIG_DIR/postgresql.conf" ]; then
    echo "✅ postgresql.conf found"
else
    echo "❌ postgresql.conf NOT found"
fi

if [ -f "$CONFIG_DIR/redis.conf" ]; then
    echo "✅ redis.conf found"
else
    echo "❌ redis.conf NOT found"
fi

if [ -d "$CONFIG_DIR/grafana" ]; then
    echo "✅ grafana config directory found"
else
    echo "❌ grafana config directory NOT found"
fi

echo ""
echo "🚀 Ready to try monitoring stack again!"
echo "Run: ./docker/scripts/start.sh monitoring"
