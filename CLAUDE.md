# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Infrastructure configuration for self-hosted VPS deployment. Two independent stacks coexist:

1. **New production stack** (`network/`, `postgres/`, `nginx-proxy/`) — modular Docker Compose folders, each standalone
2. **Legacy modular stack** (`docker/`) — base + services + profiles pattern, started via helper scripts
3. **Kubernetes stack** (`k3s/`, `apps/`, `helm-charts/`, `scripts/`) — K3s lightweight Kubernetes

## New Production Stack — Startup Order

`app_network` is defined in `network/` only. Both `postgres/` and `nginx-proxy/` reference it as `external: true`. Always start in this order:

```bash
bash network/setup.sh                        # buat app_network (idempotent)
cd postgres    && docker compose up -d
cd ../nginx-proxy && docker compose up -d
```

On reboot, Docker handles restart automatically (`restart: unless-stopped`). Order only matters for first-time setup.

## Environment Variables — Security Pattern

All password variables use `:?` (fail-fast), never `:-` (silent default). If a required env var is missing, Docker Compose errors immediately with a clear message rather than using a weak default.

`postgres/` requires a `.env` copied from `.env.example`. Key vars:

| Var | Purpose |
|-----|---------|
| `POSTGRES_CONF` | Path to config file — pick by VPS RAM |
| `POSTGRES_MEMORY_LIMIT` | Docker memory cap for the container |

PostgreSQL configs are in `postgres/configs/` — one per VPS spec (1gb/2gb/4gb). The active config is selected via `POSTGRES_CONF` env var at runtime; no file editing needed to switch specs.

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
| `app_network` | `network/docker-compose.yml` | `postgres/`, `nginx-proxy/`, new apps |
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
