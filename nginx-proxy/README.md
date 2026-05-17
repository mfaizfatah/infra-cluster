# Nginx Proxy Manager

Reverse proxy dengan UI admin berbasis web. Mendukung SSL otomatis via Let's Encrypt.

## Struktur

```
nginx-proxy/
├── data/          # Data NPM (auto-dibuat saat pertama jalan)
├── letsencrypt/   # Sertifikat SSL (auto-dibuat)
└── docker-compose.yml
```

## Prerequisites

Network `app_network` harus sudah ada (dibuat oleh service postgres). Jalankan postgres terlebih dahulu:

```bash
cd ../postgres && docker compose up -d
cd ../nginx-proxy
```

Atau buat network manual jika tidak pakai postgres:

```bash
docker network create app_network
```

## Jalankan

```bash
docker compose up -d
```

## Akses Admin UI

Port 81 hanya bind ke `127.0.0.1` (tidak bisa diakses langsung dari internet).

**Cara akses via SSH Tunnel:**

```bash
# Jalankan di komputer lokal
ssh -L 8181:127.0.0.1:81 user@IP_VPS
```

Lalu buka browser: `http://localhost:8181`

**Default login:**
- Email: `admin@example.com`
- Password: `changeme`

> Ganti email dan password segera setelah login pertama.

## Setup Proxy Host (langkah awal di UI)

1. Login ke admin UI
2. Klik **Proxy Hosts** → **Add Proxy Host**
3. Isi:
   - **Domain Names**: domain kamu (misal `app.domain.com`)
   - **Scheme**: `http`
   - **Forward Hostname/IP**: nama container (misal `myapp`) atau IP internal
   - **Forward Port**: port aplikasi
4. Tab **SSL** → pilih **Request a new SSL Certificate** → centang **Force SSL**
5. Klik **Save**

## Command Umum

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Lihat log
docker compose logs -f nginx-proxy

# Restart
docker compose restart nginx-proxy
```

## Port

| Port | Keterangan |
|------|------------|
| 80   | HTTP publik (redirect ke HTTPS) |
| 443  | HTTPS publik |
| 81   | Admin UI (localhost only, akses via SSH tunnel) |
