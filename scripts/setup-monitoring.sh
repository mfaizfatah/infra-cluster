#!/bin/bash

set -e

echo "📊 Setting up monitoring stack..."

# Check if K3s is running
if ! sudo k3s kubectl get nodes > /dev/null 2>&1; then
    echo "❌ K3s is not running. Please install K3s first."
    exit 1
fi

# Add Prometheus Helm repository
echo "📦 Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "📁 Creating monitoring namespace..."
sudo k3s kubectl create namespace monitoring --dry-run=client -o yaml | sudo k3s kubectl apply -f -

# Install kube-prometheus-stack (Prometheus + Grafana + AlertManager)
echo "⚓ Installing kube-prometheus-stack..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=5Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=2Gi \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=2Gi

# Wait for monitoring pods to be ready
echo "⏳ Waiting for monitoring stack to be ready..."
sudo k3s kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=prometheus \
  --timeout=300s

# Apply ingress for Grafana and Prometheus
echo "🌐 Setting up ingress for monitoring services..."
sudo k3s kubectl apply -f ./monitoring/

echo "✅ Monitoring stack deployed successfully!"
echo "📊 Grafana default credentials: admin / prom-operator"
echo "🔍 Checking monitoring pods..."
sudo k3s kubectl get pods -n monitoring
