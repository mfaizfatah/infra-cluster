# Infrastructure Cluster

Repository untuk setup K3s cluster dan deployment aplikasi menggunakan Helm charts.

## Spesifikasi VPS
- Memory: 1GB
- CPU: 1 Core  
- Storage: 60GB

## Struktur Repository

```
├── scripts/           # Script untuk setup dan maintenance
├── k3s/              # Konfigurasi K3s
├── helm-charts/      # Custom Helm charts
├── apps/             # Deployment aplikasi
├── monitoring/       # Setup monitoring (Prometheus, Grafana)
├── ingress/          # Konfigurasi ingress controller
└── docs/             # Dokumentasi
```

## Quick Start

1. Setup K3s cluster:
   ```bash
   ./scripts/install-k3s.sh
   ```

2. Deploy aplikasi:
   ```bash
   ./scripts/deploy-apps.sh
   ```

3. Setup monitoring:
   ```bash
   ./scripts/setup-monitoring.sh
   ```

## Dokumentasi

Lihat folder `docs/` untuk dokumentasi lengkap.
