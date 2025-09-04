# PostgreSQL Deployment

PostgreSQL database deployment untuk K3s cluster dengan optimasi untuk VPS 1GB RAM.

## 🔒 **SECURITY NOTICE**
**PENTING**: Sebelum deploy, WAJIB ganti password default!

## Fitur
- PostgreSQL 15.4 Alpine (image ringan)
- Resource limits yang dioptimalkan untuk low-memory
- Persistent storage 5GB
- Health checks (liveness & readiness probes)
- Konfigurasi PostgreSQL yang dioptimalkan

## Deployment Options

### 1. Menggunakan Helm Chart
```bash
# Deploy dengan Helm
helm install postgresql ./helm-charts/postgresql --namespace apps --create-namespace

# Dengan custom values
helm install postgresql ./helm-charts/postgresql \
  --namespace apps \
  --create-namespace \
  --set postgresql.database=myapp \
  --set postgresql.username=myuser
```

### 2. Menggunakan Kubernetes Manifests
```bash
# WAJIB: Update password dulu sebelum deploy!
# Edit apps/postgresql/deployment.yaml, ganti password default

# Deploy dengan kubectl
kubectl apply -f apps/postgresql/ --recursive
```

## 🔐 Setup Password (WAJIB)

### Generate Password Baru
```bash
# Generate secure password
NEW_PASSWORD="your-secure-password-here"

# Encode ke base64
echo -n "$NEW_PASSWORD" | base64

# Copy hasil base64 dan update di deployment.yaml
```

### Update Password di File
Edit `apps/postgresql/deployment.yaml` dan ganti:
```yaml
# Ganti Y2hhbmdlbWUxMjM= dengan password baru (base64 encoded)
postgresql-password: YOUR_BASE64_PASSWORD_HERE
```

## Akses Database

### Get Password
```bash
# Untuk Helm deployment
kubectl get secret postgresql -n apps -o jsonpath="{.data.postgresql-password}" | base64 --decode

# Untuk manifest deployment 
kubectl get secret postgresql-secret -n apps -o jsonpath="{.data.postgresql-password}" | base64 --decode
```

### Connect to Database
```bash
# Port forward untuk akses lokal
kubectl port-forward svc/postgresql-service 5432:5432 -n apps

# Connect menggunakan psql
psql -h localhost -p 5432 -U postgres -d myapp
```

### Connect dari Pod lain
```bash
# Connection string dari dalam cluster
postgresql://postgres:password@postgresql-service.apps.svc.cluster.local:5432/myapp
```

## Konfigurasi

### Resource Limits (Dioptimalkan untuk 1GB RAM)
- Memory Request: 128Mi
- Memory Limit: 256Mi
- CPU Request: 100m
- CPU Limit: 200m

### PostgreSQL Config
- shared_buffers: 32MB
- effective_cache_size: 128MB
- max_connections: 20
- work_mem: 4MB

## Backup & Restore

### Manual Backup
```bash
# Backup database
kubectl exec -n apps deployment/postgresql -- pg_dump -U postgres myapp > backup.sql

# Restore database
kubectl exec -i -n apps deployment/postgresql -- psql -U postgres myapp < backup.sql
```

## Monitoring
Database akan ter-monitor otomatis jika Anda menggunakan monitoring stack yang telah disediakan.

## 🛡️ Security Best Practices
1. **Selalu ganti password default** sebelum production
2. **Gunakan strong password** (minimal 16 karakter)
3. **Rotate password** secara berkala (3-6 bulan)
4. **Monitor database access logs**
5. **Backup teratur** dan test restore process
