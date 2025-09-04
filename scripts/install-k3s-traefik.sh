#!/bin/bash

set -e

echo "🚀 Starting K3s installation with Traefik..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y curl wget git

# Install K3s with Traefik enabled (alternative setup)
echo "⚙️ Installing K3s with Traefik ingress..."
echo "  - Keeping Traefik (built-in ingress controller)"
echo "  - Disabling ServiceLB (using NodePort/Ingress for VPS)"
echo "  - Setting memory eviction policies for 1GB RAM"
echo "  ⚠️  WARNING: Traefik uses more memory (~150MB vs 80MB for NGINX)"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable servicelb --kubelet-arg=eviction-hard=memory.available<100Mi --kubelet-arg=eviction-soft=memory.available<300Mi --kubelet-arg=eviction-soft-grace-period=memory.available=30s" sh -

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Wait for Traefik to be ready
echo "⏳ Waiting for Traefik to be ready..."
sudo k3s kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=traefik \
  --timeout=120s

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

echo "🎉 K3s with Traefik installation completed successfully!"
echo "🌐 Traefik dashboard available at: http://<your-server-ip>:8080"
echo "💡 You can now use 'k3s kubectl' or add alias for 'kubectl'"
echo "📝 Kubeconfig is available at ~/.kube/config"
