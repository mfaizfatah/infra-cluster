# PostgreSQL Exporter Guide

PostgreSQL Exporter untuk mengumpulkan metrics dari database PostgreSQL dan memonitor performance database.

## 🚀 **Cara Menjalankan PostgreSQL Exporter**

### 1. **Menggunakan Helper Script (Recommended)**
```bash
# Option 1: Start PostgreSQL + PostgreSQL Exporter (sequential)
./docker/scripts/postgres-exporter.sh start

# Option 2: Start database stack + exporters together (recommended)
./docker/scripts/postgres-exporter.sh start-with-database

# Check status
./docker/scripts/postgres-exporter.sh status

# View logs
./docker/scripts/postgres-exporter.sh logs

# Test metrics
./docker/scripts/postgres-exporter.sh metrics

# Test database connection
./docker/scripts/postgres-exporter.sh connect-test
```

### 2. **Manual dengan Docker Compose (Fixed)**
```bash
# Option A: Start PostgreSQL first, then exporter
./docker/scripts/start.sh database
# Wait for PostgreSQL to be ready (15-30 seconds)
docker-compose -f docker/services/monitoring-exporters.yml up -d postgres-exporter

# Option B: Start both together using multiple compose files
docker-compose -f docker/profiles/database.yml -f docker/services/monitoring-exporters.yml up -d
```

### 3. **Dengan Monitoring Stack Lengkap**
```bash
# Start monitoring stack (includes postgres-exporter automatically)
./docker/scripts/start.sh monitoring
```

### 4. **Individual Exporter Only (PostgreSQL must be running)**
```bash
# Start only postgres-exporter (PostgreSQL must already be running)
docker-compose -f docker/services/monitoring-exporters.yml up -d postgres-exporter
```

## 🔧 **Konfigurasi Environment Variables**

Buat file `.env` di folder `docker/` dengan konfigurasi database:

```bash
# Copy template
cp docker/.env.postgres-exporter docker/.env

# Edit dengan credentials database Anda
nano docker/.env
```

### **Environment Variables yang Didukung:**
```bash
# Database profile variables (prioritas utama)
DB_USER=appuser
DB_PASSWORD=secure_password_123
DB_NAME=appdb

# Fallback ke regular variables
POSTGRES_USER=postgres
POSTGRES_PASSWORD=changeme123
POSTGRES_DB=myapp
```

## 📊 **Metrics yang Dikumpulkan**

PostgreSQL Exporter mengumpulkan metrics berikut:

### **Connection Metrics**
- `pg_up` - Status koneksi database (1 = connected, 0 = disconnected)
- `pg_stat_activity_count` - Jumlah koneksi aktif
- `pg_settings_max_connections` - Maximum connections allowed

### **Database Size Metrics**
- `pg_database_size_bytes` - Ukuran database dalam bytes
- `pg_stat_database_tup_returned` - Total tuples returned
- `pg_stat_database_tup_fetched` - Total tuples fetched

### **Performance Metrics**
- `pg_stat_database_blks_read` - Disk blocks read
- `pg_stat_database_blks_hit` - Buffer hits
- `pg_stat_database_xact_commit` - Transactions committed
- `pg_stat_database_xact_rollback` - Transactions rolled back

### **Table Metrics**
- `pg_stat_user_tables_seq_scan` - Sequential scans
- `pg_stat_user_tables_idx_scan` - Index scans
- `pg_stat_user_tables_n_tup_ins` - Tuples inserted
- `pg_stat_user_tables_n_tup_upd` - Tuples updated

## 🔍 **Verifikasi dan Troubleshooting**

### **Check Container Status**
```bash
# Status postgres-exporter
docker ps | grep postgres-exporter

# Logs detail
docker logs infra-postgres-exporter -f
```

### **Test Metrics Endpoint**
```bash
# Test metrics collection
docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics | head -20

# Test specific metrics
docker exec infra-postgres-exporter wget -qO- http://localhost:9187/metrics | grep pg_up
```

### **Common Issues & Solutions**

#### **Connection Error**
```bash
# Error: "connection refused"
# Solution: Pastikan PostgreSQL berjalan dan credentials benar

# Check PostgreSQL status
docker ps | grep postgresql

# Verify connection string
echo $DATA_SOURCE_NAME
```

#### **No Metrics**
```bash
# Error: "no metrics returned"
# Solution: Check database permissions

# Test database connection
docker exec infra-postgresql psql -U $DB_USER -d $DB_NAME -c "SELECT version();"
```

#### **Permission Denied**
```bash
# Error: "permission denied for schema pg_catalog"
# Solution: Grant monitoring permissions to database user

# Connect to database
docker exec -it infra-postgresql psql -U postgres -d myapp

# Grant permissions
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO your_user;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO your_user;
```

## 🎯 **Viewing Metrics in Grafana**

PostgreSQL metrics akan otomatis tersedia di Grafana jika monitoring stack berjalan:

1. **Access Grafana**: http://your-vps-ip:3000
2. **Login**: admin / admin123
3. **Navigate**: Explore > Prometheus
4. **Query**: `pg_up` untuk melihat status database

### **Useful Prometheus Queries**
```promql
# Database status
pg_up

# Connection count
pg_stat_activity_count

# Database size in MB
pg_database_size_bytes / 1024 / 1024

# Cache hit ratio
pg_stat_database_blks_hit / (pg_stat_database_blks_hit + pg_stat_database_blks_read) * 100
```

## 🔐 **Security Notes**

- PostgreSQL Exporter tidak terekspos ke public (internal-only)
- Metrics hanya dapat diakses melalui Grafana dashboard
- Credentials database disimpan sebagai environment variables
- Connection menggunakan standard PostgreSQL authentication

## 📈 **Performance Impact**

- **Memory**: ~16-32MB
- **CPU**: Minimal impact
- **Network**: Metrics collection setiap 15 detik
- **Database Load**: Query metadata tables, minimal impact pada performance
