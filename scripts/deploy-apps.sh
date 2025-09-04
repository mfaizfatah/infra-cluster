#!/bin/bash

set -e

echo "🚀 Deploying applications to K3s cluster..."

# Check if K3s is running
if ! sudo k3s kubectl get nodes > /dev/null 2>&1; then
    echo "❌ K3s is not running. Please install K3s first."
    exit 1
fi

# Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
sudo k3s kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Wait for ingress controller to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
sudo k3s kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Create namespace for applications
echo "📁 Creating application namespaces..."
sudo k3s kubectl create namespace apps --dry-run=client -o yaml | sudo k3s kubectl apply -f -

# Deploy applications from helm charts
if [ -d "./helm-charts" ]; then
    echo "⚓ Deploying Helm charts..."
    for chart in ./helm-charts/*/; do
        if [ -d "$chart" ]; then
            chart_name=$(basename "$chart")
            echo "📦 Deploying $chart_name..."
            helm upgrade --install "$chart_name" "$chart" --namespace apps --create-namespace
        fi
    done
fi

# Apply individual application manifests
if [ -d "./apps" ]; then
    echo "📋 Applying application manifests..."
    for app_dir in ./apps/*/; do
        if [ -d "$app_dir" ]; then
            app_name=$(basename "$app_dir")
            echo "🔧 Deploying $app_name..."
            sudo k3s kubectl apply -f "$app_dir" --recursive
        fi
    done
fi

echo "✅ Application deployment completed!"
echo "🔍 Checking deployed applications..."
sudo k3s kubectl get pods -n apps
sudo k3s kubectl get ingress -n apps
