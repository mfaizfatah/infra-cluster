#!/bin/bash

set -e

echo "🚀 Starting K3s installation..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y curl wget git

# Install K3s with optimized settings for 1GB RAM
echo "⚙️ Installing K3s with memory optimization..."
echo "  - Disabling Traefik (using NGINX Ingress instead)"
echo "  - Disabling ServiceLB (using NodePort/Ingress for VPS)"
echo "  - Setting memory eviction policies for 1GB RAM"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --kubelet-arg=eviction-hard=memory.available<100Mi --kubelet-arg=eviction-soft=memory.available<300Mi --kubelet-arg=eviction-soft-grace-period=memory.available=30s" sh -

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Create kubeconfig for regular user
echo "🔐 Setting up kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# Install kubectl (alias to k3s kubectl)
echo "📋 Setting up kubectl alias..."
echo 'alias kubectl="k3s kubectl"' >> ~/.bashrc
source ~/.bashrc

# Install Helm
echo "⚓ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
echo "✅ Verifying installation..."
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A

echo "🎉 K3s installation completed successfully!"
echo "💡 You can now use 'k3s kubectl' or add alias for 'kubectl'"
echo "📝 Kubeconfig is available at ~/.kube/config"
