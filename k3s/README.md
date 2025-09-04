# K3s Configuration

## Server Configuration
Konfigurasi K3s server dioptimalkan untuk VPS dengan 1GB RAM:

```bash
# Disable traefik (kita akan pakai NGINX Ingress)
--disable traefik

# Disable servicelb (kita akan pakai NodePort)
--disable servicelb

# Memory eviction settings
--kubelet-arg=eviction-hard=memory.available<100Mi
--kubelet-arg=eviction-soft=memory.available<300Mi
--kubelet-arg=eviction-soft-grace-period=memory.available=30s
```

## Resource Limits
Untuk VPS dengan 1GB RAM, sangat penting mengatur resource limits:

- System reserved: ~200MB
- K3s components: ~300MB
- Available for workloads: ~500MB

## Best Practices
1. Selalu set resource requests dan limits untuk semua pods
2. Gunakan PriorityClass untuk critical workloads
3. Monitor memory usage secara berkala
4. Gunakan HPA (Horizontal Pod Autoscaler) dengan hati-hati
