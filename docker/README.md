# Docker Compose Setup

Docker Compose setup yang modular dan dinamis untuk development environment.

## Struktur

```
docker/
├── base/                    # Core services
│   └── docker-compose.yml   # Base configuration
├── services/                # Individual services
│   ├── postgresql.yml       # PostgreSQL database
│   ├── prometheus.yml       # Prometheus monitoring
│   ├── grafana.yml         # Grafana dashboard
│   ├── redis.yml           # Redis cache
│   └── nginx.yml           # NGINX proxy
├── profiles/               # Predefined combinations
│   ├── database.yml        # Database stack
│   ├── monitoring.yml      # Monitoring stack
│   └── full.yml           # All services
└── scripts/               # Helper scripts
    ├── start.sh           # Start specific services
    ├── stop.sh            # Stop services
    └── logs.sh            # View logs
```

## Quick Start

### Start Individual Services
```bash
# PostgreSQL only
./docker/scripts/start.sh postgresql

# Monitoring stack (Prometheus + Grafana)
./docker/scripts/start.sh monitoring

# All services
./docker/scripts/start.sh full
```

### Manual Compose
```bash
# PostgreSQL + Redis
docker-compose -f docker/base/docker-compose.yml -f docker/services/postgresql.yml -f docker/services/redis.yml up -d

# Full monitoring stack
docker-compose -f docker/profiles/monitoring.yml up -d
```
