# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Infrastructure configuration for self-hosted VPS deployment. Two independent stacks coexist:

1. **New production stack** (`network/`, `postgres/`, `nginx-proxy/`, `redis/`) — modular Docker Compose folders, each standalone
2. **Legacy modular stack** (`docker/`) — base + services + profiles pattern, started via helper scripts
3. **Kubernetes stack** (`k3s/`, `apps/`, `helm-charts/`, `scripts/`) — K3s lightweight Kubernetes

Production VPS for the `terangjakarta-web-backend` stack (`postgres`, `nginx-proxy`, `redis`): 3.8GB RAM / 2 CPU core (confirmed via `free -h` / `nproc` on the server — do not trust the 1GB/1-core spec in the root README, that describes the separate K3s stack).

## New Production Stack — Startup Order

`app_network` is defined in `network/` only. `postgres/`, `nginx-proxy/`, and `redis/` all reference it as `external: true`. Always start in this order:

```bash
bash network/setup.sh                        # buat app_network (idempotent)
cd postgres    && docker compose up -d
cd ../nginx-proxy && docker compose up -d
cd ../redis    && docker compose up -d
```

On reboot, Docker handles restart automatically (`restart: unless-stopped`). Order only matters for first-time setup.

## Resource Limits — New Production Stack (3.8GB / 2-core VPS)

Every service in the new production stack sets Docker `deploy.resources.limits`/`reservations`, overridable per-service via that folder's `.env` (never edit `docker-compose.yml` directly to change a limit):

| Service | Memory limit | Memory reservation | CPU limit |
|---|---|---|---|
| `postgres` | 2.5G (`POSTGRES_MEMORY_LIMIT`) | 1G | — |
| `redis` | 256m (`REDIS_MEMORY_LIMIT`) | 128m | 0.5 (`REDIS_CPU_LIMIT`) |
| `terangjakarta-web-backend` (staging) | 128m | — | — |
| `terangjakarta-web-backend` (prod), `nginx-proxy-manager` | unbounded (no `--memory` flag set at deploy) | — | — |

`redis`'s internal `maxmemory` (128mb, `REDIS_MAXMEMORY`) is intentionally smaller than its Docker memory limit — the gap is headroom for the Redis process itself (client connections, AOF rewrite buffer), not data storage. See `redis/README.md`.

## Environment Variables — Security Pattern

All password variables use `:?` (fail-fast), never `:-` (silent default). If a required env var is missing, Docker Compose errors immediately with a clear message rather than using a weak default.

`postgres/` and `redis/` each require a `.env` copied from that folder's `.env.example`. Key vars:

| Var | Purpose |
|-----|---------|
| `POSTGRES_CONF` | Path to config file — pick by VPS RAM |
| `POSTGRES_MEMORY_LIMIT` | Docker memory cap for the container |
| `REDIS_PASSWORD` | `requirepass` — fail-fast (`:?`), no default |
| `REDIS_MAXMEMORY` | Redis-internal `maxmemory` (data budget, not the Docker limit) |
| `REDIS_MEMORY_LIMIT` | Docker memory cap for the container — kept above `REDIS_MAXMEMORY` for process overhead headroom |

PostgreSQL configs are in `postgres/configs/` — one per VPS spec (1gb/2gb/4gb). The active config is selected via `POSTGRES_CONF` env var at runtime; no file editing needed to switch specs. Redis has no per-tier config files (unlike Postgres, its memory tuning is a single `maxmemory` knob) — just adjust `REDIS_MAXMEMORY`/`REDIS_MEMORY_LIMIT` in `.env` directly.

## Legacy Docker Stack Commands

```bash
# Start by profile
./docker/scripts/start.sh database      # PostgreSQL + Redis
./docker/scripts/start.sh monitoring    # Prometheus + Grafana
./docker/scripts/start.sh full          # All services

# Start individual services
./docker/scripts/start.sh postgresql redis

# Manual compose (run from docker/ dir)
docker-compose -f base/docker-compose.yml -f services/postgresql.yml up -d
```

Scripts must be run from repo root; they resolve paths relative to themselves.

## Kubernetes Stack Commands

```bash
make install    # Install K3s cluster
make deploy     # Deploy all apps
make monitor    # Setup monitoring
make status     # Check nodes and pods
make clean      # Uninstall K3s
make logs       # Tail K3s logs
```

Raw kubectl: `sudo k3s kubectl <command>`

## Two Networks — Do Not Mix

| Network | Defined in | Used by |
|---------|-----------|---------|
| `app_network` | `network/docker-compose.yml` | `postgres/`, `nginx-proxy/`, `redis/`, new apps |
| `infra-network` | `docker/base/docker-compose.yml` | Everything in `docker/` |

New services should join `app_network` (external). Add to any compose file:

```yaml
networks:
  app_network:
    external: true
    name: app_network
```

## Nginx Proxy Manager Admin UI

Port 81 binds to `127.0.0.1` only. Access via SSH tunnel from local machine:

```bash
ssh -L 8181:127.0.0.1:81 root@IP_VPS
# then open http://localhost:8181
```

## Adding a New App to the Stack

1. Create a folder with `docker-compose.yml`
2. Join `app_network` as external (see snippet above)
3. Add to Nginx Proxy Manager via UI — no config file changes needed
4. Expose only internal ports; let NPM handle public HTTPS
