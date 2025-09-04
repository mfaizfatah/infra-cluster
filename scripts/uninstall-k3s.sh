#!/bin/bash

set -e

echo "🗑️ Uninstalling K3s..."

# Stop K3s service
sudo systemctl stop k3s

# Run K3s uninstall script
sudo /usr/local/bin/k3s-uninstall.sh

# Clean up remaining files
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /etc/rancher/k3s
sudo rm -f ~/.kube/config

echo "✅ K3s uninstalled successfully!"
