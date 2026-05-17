#!/bin/bash
set -e

NETWORK_NAME="app_network"

if docker network inspect "$NETWORK_NAME" &>/dev/null; then
    echo "Network '$NETWORK_NAME' already exists."
else
    docker network create --driver bridge "$NETWORK_NAME"
    echo "Network '$NETWORK_NAME' created."
fi
