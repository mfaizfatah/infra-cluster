# PostgreSQL

PostgreSQL 16 dengan konfigurasi per-spek VPS dan init script otomatis untuk multi-database.

## Struktur

```
postgres/
├── configs/
│   ├── postgresql-1gb.conf   # Tuned untuk 1GB RAM
│   ├── postgresql-2gb.conf   # Tuned untuk 2GB RAM
│   └── postgresql-4gb.conf   # Tuned untuk 4GB RAM
├── initdb/
│   └── init-databases.sh     # Auto-create DB + user saat container pertama kali jalan
├── .env                      # Credentials (tidak di-commit)
├── .env.example              # Template .env
└── docker-compose.yml
```

## Setup

### 1. Buat file .env

```bash
cp .env.example .env
nano .env
```

Isi sesuai kebutuhan, terutama:
- Password (ganti dengan password kuat)
- `POSTGRES_CONF` → pilih sesuai RAM VPS
- `POSTGRES_MEMORY_LIMIT` → sesuai RAM VPS

### 2. Jalankan

```bash
docker compose up -d
```

### 3. Cek status

```bash
docker compose ps
docker compose logs -f postgres
```

## Konfigurasi per VPS

| VPS RAM | Config file              | Memory Limit | Reservation |
|---------|--------------------------|-------------|-------------|
| 1GB     | `postgresql-1gb.conf`    | 512m        | 256m        |
| 2GB     | `postgresql-2gb.conf`    | 1.2G        | 512M        |
| 4GB     | `postgresql-4gb.conf`    | 2.5G        | 1G          |

## Tambah Database Baru

Edit `initdb/init-databases.sh`, tambah variabel baru di `.env` dan `.env.example`, lalu panggil fungsi `create_database_and_user`.

> **Catatan:** Init script hanya berjalan saat volume postgres pertama kali dibuat. Jika sudah ada volume, hapus dulu dengan `docker compose down -v`.

## Command Umum

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Lihat log
docker compose logs -f postgres

# Masuk psql
docker exec -it postgres psql -U admin -d postgres

# Backup database
docker exec postgres pg_dump -U admin nama_db > backup.sql

# Restore database
docker exec -i postgres psql -U admin nama_db < backup.sql

# Reset total (hapus semua data)
docker compose down -v
```

## Network

Postgres join ke `app_network` yang dibuat oleh folder `network/`. Pastikan network sudah ada sebelum menjalankan postgres:

```bash
cd ../network && docker compose up -d
```

Service lain yang ingin connect ke postgres cukup join ke network yang sama:

```yaml
networks:
  app_network:
    external: true
    name: app_network
```
