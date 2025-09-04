# Dokumentasi Setup K3s dan Deployment Aplikasi

## Prerequisites
- VPS dengan Ubuntu/Debian
- Root access atau sudo privileges
- Koneksi internet stabil

## Langkah-langkah Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd infra-cluster
```

### 2. Setup K3s
```bash
# Copy script ke server
scp -r scripts/ user@your-server:~/

# SSH ke server
ssh user@your-server

# Jalankan instalasi K3s
chmod +x scripts/*.sh
./scripts/install-k3s.sh
```

### 3. Deploy Aplikasi
```bash
# Deploy semua aplikasi
./scripts/deploy-apps.sh

# Setup monitoring (opsional)
./scripts/setup-monitoring.sh
```

### 4. Akses Aplikasi
Tambahkan entry berikut ke `/etc/hosts` di komputer lokal:
```
<your-server-ip> nginx.local
<your-server-ip> webapp.local
<your-server-ip> grafana.local
<your-server-ip> prometheus.local
```

## Resource Management
Dengan RAM 1GB, sangat penting untuk:
- Selalu set resource limits
- Monitor penggunaan memory
- Gunakan image yang ringan (alpine)
- Limit jumlah replicas

## Troubleshooting
### Pod OOMKilled
```bash
# Check memory usage
kubectl top nodes
kubectl top pods -A

# Adjust resource limits di values.yaml atau deployment
```

### Node NotReady
```bash
# Check K3s status
sudo systemctl status k3s

# Check logs
sudo journalctl -u k3s -f
```
