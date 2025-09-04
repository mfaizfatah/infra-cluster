# System Monitoring untuk VPS dengan Prometheus

Prometheus sekarang dikonfigurasi untuk memonitor seluruh sistem VPS Anda secara komprehensif.

## 📊 **Monitoring Components**

### 1. **Node Exporter** (System Metrics)
- **CPU Usage**: Utilization per core dan load average
- **Memory**: Total, used, available, swap usage  
- **Disk**: Space usage, I/O operations, read/write stats
- **Network**: Interface traffic, packets, errors
- **Process**: Running processes, file descriptors

### 2. **PostgreSQL Exporter** (Database Metrics)
- **Connection**: Active connections, max connections
- **Query Performance**: Slow queries, query duration
- **Database Size**: Table sizes, index usage
- **Replication**: Lag, status (jika ada)

### 3. **Redis Exporter** (Cache Metrics)
- **Memory Usage**: Used vs allocated memory
- **Operations**: Commands per second, hit rate
- **Connections**: Connected clients
- **Persistence**: RDB/AOF status

### 4. **cAdvisor** (Container Metrics)
- **Container Resources**: CPU, memory per container
- **Container Health**: Status, restart count
- **Docker Stats**: Image info, network usage

## 🚨 **Alert Rules**

### Memory Alerts (Critical untuk VPS 1GB)
- **Warning**: >85% memory usage
- **Critical**: >95% memory usage (sistem bisa hang!)

### CPU & Load
- **Warning**: >80% CPU usage untuk 5 menit
- **Warning**: Load average >2 untuk 5 menit

### Disk Space
- **Warning**: <20% free space
- **Critical**: <10% free space

### Database Health
- **Critical**: PostgreSQL/Redis down
- **Warning**: PostgreSQL >15 connections (dari limit 20)
- **Warning**: Redis >90% memory usage

## 🎯 **Cara Menggunakan**

### Start Monitoring Stack
```bash
# Full monitoring dengan system metrics
./docker/scripts/start.sh monitoring

# Atau individual services
./docker/scripts/start.sh prometheus grafana node-exporter
```

### Access Monitoring
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Node Exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080

### View Logs
```bash
# Monitor semua service
./docker/scripts/logs.sh all -f

# Monitor specific exporter
./docker/scripts/logs.sh node-exporter -f
```

## 📈 **Key Metrics untuk VPS 1GB**

### Memory Monitoring (CRITICAL)
```promql
# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Available memory in MB
node_memory_MemAvailable_bytes / 1024 / 1024
```

### CPU Monitoring
```promql
# CPU usage percentage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Load average
node_load1
```

### Disk Monitoring
```promql
# Disk usage percentage
(1 - (node_filesystem_free_bytes / node_filesystem_size_bytes)) * 100

# Free disk space in GB
node_filesystem_free_bytes / 1024 / 1024 / 1024
```

### Container Resources
```promql
# Container memory usage
container_memory_usage_bytes / 1024 / 1024

# Container CPU usage
rate(container_cpu_usage_seconds_total[5m]) * 100
```

## ⚠️ **Resource Impact**

Total monitoring stack memory usage:
- **Node Exporter**: ~32-64MB
- **Postgres Exporter**: ~16-32MB  
- **Redis Exporter**: ~16-32MB
- **cAdvisor**: ~64-128MB
- **Prometheus**: ~128-256MB
- **Grafana**: ~96-192MB

**Total**: ~350-700MB (cocok untuk VPS 1GB dengan careful usage)

## 🔧 **Best Practices**

1. **Monitor Gradually**: Start dengan node-exporter dulu, lalu tambah exporter lain
2. **Watch Memory**: Gunakan `docker stats` untuk monitor real-time usage
3. **Retention Settings**: Keep hanya 7 hari data untuk hemat disk space
4. **Alert Setup**: Set alert ke email/Slack untuk monitoring remote

## 🚨 **Emergency Response**

Jika system hampir OOM:
```bash
# Stop monitoring immediately
./docker/scripts/stop.sh monitoring

# Check what's using memory
docker stats
free -h
```
