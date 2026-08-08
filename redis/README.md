# Redis

Redis 7.2 untuk email queue (durable, `noeviction`) dan generic cache (fail-soft).

## Struktur

```
redis/
├── .env                # Credentials (tidak di-commit)
├── .env.example         # Template .env
└── docker-compose.yml
```

## Setup

### 1. Buat file .env

```bash
cp .env.example .env
nano .env
```

Isi sesuai kebutuhan — minimal `REDIS_PASSWORD` (ganti dengan password kuat). `REDIS_MAXMEMORY` dan resource limits Docker sudah punya default yang aman untuk VPS produksi saat ini (3.8GB RAM / 2 CPU core — cek [Resource Limits](#resource-limits) di bawah).

### 2. Pastikan `app_network` sudah ada

```bash
cd ../network && bash setup.sh
```

### 3. Jalankan

```bash
docker compose up -d
```

### 4. Cek status

```bash
docker compose ps
docker compose logs -f redis
docker exec redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning ping   # → PONG
```

## Resource Limits

| VPS saat ini | 3.8GB RAM / 2 CPU core (dicek langsung via `free -h` / `nproc` di server produksi) |
|---|---|
| `postgres` (service lain di VM yang sama) | limit 2.5G memory |
| `redis` — internal `maxmemory` | **128mb** (kontrol eviction/OOM data Redis sendiri) |
| `redis` — Docker `memory` limit | **256m** (di atas `maxmemory` — kasih headroom proses: koneksi client + buffer `BGREWRITEAOF` yang bisa numpuk ~2x saat AOF rewrite) |
| `redis` — Docker `memory` reservation | 128m |
| `redis` — Docker `cpus` limit | 0.5 core |
| `redis` — Docker `cpus` reservation | 0.1 core |

Email queue job kecil (~1-2KB per job JSON) — 128MB muat puluhan ribu job pending, jauh di atas volume spike traffic mingguan yang jadi alasan fitur ini dibuat (lihat ADR-009). Kalau VPS di-upgrade atau kebutuhan cache membesar signifikan, naikkan `REDIS_MAXMEMORY` + `REDIS_MEMORY_LIMIT` di `.env` — tidak perlu redeploy code, tinggal `docker compose up -d` ulang.

Semua limit di atas bisa di-override lewat `.env` tanpa edit `docker-compose.yml` (lihat `.env.example`), pola yang sama seperti `POSTGRES_MEMORY_LIMIT` di `../postgres/.env.example`.

## Command Umum

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Lihat log
docker compose logs -f redis

# Masuk redis-cli
docker exec -it redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning

# Lihat job pending / failed
docker exec redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning LLEN emailqueue:pending
docker exec redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning LLEN emailqueue:failed

# Reset total (hapus semua data — job pending/failed akan hilang)
docker compose down -v
```

## Network

Redis join ke `app_network` yang dibuat oleh folder `network/` — sama seperti `postgres/`. Pastikan network sudah ada sebelum menjalankan redis:

```bash
cd ../network && bash setup.sh
```

Port **hanya** di-bind ke `127.0.0.1:6379` (bukan `0.0.0.0`) — sama seperti pola `postgres/` (`127.0.0.1:5432`). Backend app connect lewat Docker DNS di `app_network` (hostname `redis`, port `6379`), bukan lewat port yang di-publish; port loopback ini murni untuk debugging manual via SSH tunnel:

```bash
ssh -L 16379:127.0.0.1:6379 <ssh-alias>
redis-cli -h localhost -p 16379 -a "$REDIS_PASSWORD" --no-auth-warning ping
```

Service lain yang ingin connect ke redis cukup join ke network yang sama dan pakai hostname `redis`:

```yaml
networks:
  app_network:
    external: true
    name: app_network
```

## Config di terangjakarta-web-backend

`config.json`:

```json
"redis": {
  "addr": "redis:6379",
  "password": "<isi sama dengan REDIS_PASSWORD di .env sini>",
  "db": 0,
  "email_rate_per_second": 2.0
}
```
