# Tutorial Deploy ke VPS

Panduan lengkap deploy stack **Nginx Proxy Manager + PostgreSQL** ke VPS Ubuntu/Debian.

---

## Prerequisites

- VPS dengan Ubuntu 22.04 / Debian 12
- Akses SSH sebagai root atau user dengan sudo
- Domain yang sudah diarahkan ke IP VPS (untuk SSL)

---

## Langkah 1 — Install Docker di VPS

SSH ke VPS terlebih dahulu:

```bash
ssh root@IP_VPS
```

Install Docker (satu perintah):

```bash
curl -fsSL https://get.docker.com | sh
```

Verifikasi:

```bash
docker --version
docker compose version
```

---

## Langkah 2 — Clone Repository

```bash
git clone https://github.com/USERNAME/infra-cluster.git
cd infra-cluster
```

---

## Langkah 3 — Buat Shared Network

Network `app_network` dibuat sekali dan dipakai bersama oleh semua service.

```bash
bash network/setup.sh
```

Verifikasi:

```bash
docker network ls | grep app_network
```

---

## Langkah 4 — Setup PostgreSQL

```bash
cd postgres
```

### 4a. Buat file .env

```bash
cp .env.example .env
nano .env
```

Isi sesuai spek VPS kamu:

**VPS 1GB RAM:**
```env
POSTGRES_CONF=./configs/postgresql-1gb.conf
POSTGRES_MEMORY_LIMIT=512m
POSTGRES_MEMORY_RESERVATION=256m
```

**VPS 2GB RAM:**
```env
POSTGRES_CONF=./configs/postgresql-2gb.conf
POSTGRES_MEMORY_LIMIT=1.2G
POSTGRES_MEMORY_RESERVATION=512M
```

**VPS 4GB RAM:**
```env
POSTGRES_CONF=./configs/postgresql-4gb.conf
POSTGRES_MEMORY_LIMIT=2.5G
POSTGRES_MEMORY_RESERVATION=1G
```

Ganti juga semua password dengan password yang kuat.

### 4b. Jalankan PostgreSQL

```bash
docker compose up -d
```

### 4c. Verifikasi

```bash
docker compose ps
# STATUS harus "healthy"

docker compose logs postgres
# Lihat apakah ada error
```

---

## Langkah 5 — Setup Nginx Proxy Manager

```bash
cd ../nginx-proxy
docker compose up -d
```

Verifikasi:

```bash
docker compose ps
docker compose logs nginx-proxy
```

---

## Langkah 6 — Akses Admin UI Nginx Proxy Manager

Port admin (81) hanya bisa diakses dari localhost VPS. Gunakan SSH tunnel:

**Di komputer lokal kamu:**

```bash
ssh -L 8181:127.0.0.1:81 root@IP_VPS
```

Buka browser: `http://localhost:8181`

**Default login:**
- Email: `admin@example.com`
- Password: `changeme`

> Ganti email dan password segera setelah login pertama.

---

## Langkah 7 — Setup Proxy Host & SSL

### 6a. Tambah Proxy Host

1. Login ke NPM admin UI
2. Klik **Proxy Hosts** → **Add Proxy Host**
3. Tab **Details:**
   - **Domain Names**: `app.domain.com`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: nama container Docker atau IP internal
   - **Forward Port**: port aplikasi
4. Tab **SSL:**
   - Pilih **Request a new SSL Certificate**
   - Centang **Force SSL** dan **HTTP/2 Support**
   - Centang **I Agree to the Let's Encrypt ToS**
5. Klik **Save**

SSL otomatis di-generate dan auto-renew oleh NPM.

---

## Urutan Startup yang Benar

```
1. network/    → membuat app_network (sekali saja)
2. postgres/   → join app_network, menjalankan DB
3. nginx-proxy → join app_network
4. apps lain   → join app_network yang sama
```

Saat reboot VPS, Docker otomatis restart container (`restart: unless-stopped`). Network `app_network` bersifat persisten — tidak perlu dibuat ulang kecuali dihapus manual.

---

## Command Sehari-hari

### PostgreSQL

```bash
cd ~/infra-cluster/postgres

# Lihat status
docker compose ps

# Lihat log
docker compose logs -f postgres

# Masuk psql
docker exec -it postgres psql -U admin -d postgres

# Backup database
docker exec postgres pg_dump -U admin nama_db > /root/backup-$(date +%Y%m%d).sql

# Restore database
docker exec -i postgres psql -U admin nama_db < backup.sql

# Restart
docker compose restart postgres
```

### Nginx Proxy Manager

```bash
cd ~/infra-cluster/nginx-proxy

# Lihat status
docker compose ps

# Lihat log
docker compose logs -f nginx-proxy

# Restart
docker compose restart nginx-proxy
```

---

## Troubleshooting

### Error: network app_network not found

Folder `network/` belum dijalankan. Buat networknya dulu:

```bash
bash network/setup.sh
```

### Error: port 80/443 already in use

Ada service lain yang memakai port tersebut. Cek:

```bash
ss -tlnp | grep -E ':80|:443'
# atau
sudo lsof -i :80
```

Biasanya Apache atau Nginx native. Hentikan dulu:

```bash
systemctl stop apache2   # atau nginx
systemctl disable apache2
```

### Postgres tidak healthy

Cek log:

```bash
docker compose logs postgres
```

Kemungkinan penyebab:
- Password salah di `.env`
- Memory limit terlalu besar untuk VPS
- Port 5432 sudah dipakai oleh postgres native

### SSL gagal di-generate

Pastikan:
1. Domain sudah pointing ke IP VPS (`dig app.domain.com`)
2. Port 80 dan 443 terbuka di firewall VPS
3. Tidak ada typo pada nama domain di NPM

Cek firewall:

```bash
ufw status
ufw allow 80
ufw allow 443
```

---

## Keamanan

- Port 5432 (PostgreSQL) hanya bind ke `127.0.0.1` — tidak bisa diakses dari internet
- Port 81 (NPM admin) hanya bind ke `127.0.0.1` — akses via SSH tunnel
- Port 80 dan 443 terbuka untuk traffic web publik
- Gunakan password yang kuat dan berbeda untuk setiap user database
