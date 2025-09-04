# Security Update: Internal-Only Monitoring Services

## Perubahan Keamanan

Untuk meningkatkan keamanan deployment, service monitoring berikut ini sekarang hanya dapat diakses secara internal di dalam Docker network dan tidak terekspos ke public:

### Services yang Tidak Lagi Terekspos ke Public:
- **Prometheus** (port 9090) - Metrics collection
- **Node Exporter** (port 9100) - System metrics  
- **cAdvisor** (port 8080) - Container metrics
- **PostgreSQL Exporter** (port 9187) - Database metrics
- **Redis Exporter** (port 9121) - Cache metrics

### Services yang Masih Terekspos (Aman untuk Public):
- **Grafana** (port 3000) - Dashboard dengan authentication

## Cara Akses Monitoring

### 1. Grafana Dashboard (Public Access)
```bash
# Akses langsung via browser
http://your-vps-ip:3000
# Login: admin / admin123
```

### 2. Internal Services (Hanya dari dalam Docker Network)
Services monitoring lainnya hanya dapat diakses:
- Dari container lain dalam network yang sama
- Via Grafana dashboard yang sudah terkonfigurasi
- Melalui port forwarding untuk debugging

### 3. Port Forwarding untuk Debugging (Jika Diperlukan)
```bash
# Akses Prometheus untuk debugging
docker exec -it infra-grafana curl http://prometheus:9090

# Atau gunakan port forwarding
docker port infra-prometheus
```

## Keuntungan Keamanan

1. **Reduced Attack Surface**: Mengurangi port yang terbuka ke internet
2. **Data Protection**: Metrics sensitif hanya dapat diakses secara internal
3. **Centralized Access**: Semua monitoring data tetap dapat diakses melalui Grafana
4. **Better Security Posture**: Mengikuti security best practices

## Monitoring Tetap Berfungsi Penuh

Meskipun service tidak terekspos ke public, monitoring tetap berfungsi penuh:
- Prometheus tetap mengumpulkan metrics dari semua exporter
- Grafana tetap dapat mengakses data Prometheus
- Alert rules tetap aktif dan berfungsi
- Dashboard tetap menampilkan semua metrics

## Jika Perlu Akses Langsung (Development)

Untuk development atau debugging, Anda dapat temporary mengaktifkan port mapping dengan mengubah file konfigurasi:

```yaml
# Uncomment baris ini di monitoring.yml untuk akses sementara
ports:
  - "9090:9090"  # Prometheus
  - "9100:9100"  # Node Exporter  
  - "8080:8080"  # cAdvisor
```

**Ingat**: Selalu comment kembali port mapping untuk production!
