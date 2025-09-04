# Folder untuk deployment aplikasi menggunakan plain Kubernetes manifests

Folder ini berisi contoh aplikasi yang di-deploy menggunakan Kubernetes manifests biasa (bukan Helm).

## Struktur
```
apps/
├── nginx-example/       # Contoh aplikasi NGINX
├── postgres/           # Database PostgreSQL
└── redis/             # Redis cache
```

## Cara Deploy
```bash
# Deploy semua aplikasi
./scripts/deploy-apps.sh

# Deploy aplikasi tertentu
kubectl apply -f apps/nginx-example/ --recursive
```
