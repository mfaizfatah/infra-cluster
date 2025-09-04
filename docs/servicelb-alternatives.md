# ServiceLB vs Alternatif untuk VPS Single Node

## Mengapa ServiceLB Di-disable?

### 1. **VPS Single Node Limitations**
- ServiceLB dirancang untuk cluster multi-node
- Di single node, tidak ada load balancing yang sesungguhnya
- External IP assignment tidak bekerja di VPS standar

### 2. **Resource Overhead**
- ServiceLB daemon menggunakan ~50MB RAM
- Untuk VPS 1GB RAM, setiap MB sangat berharga
- Pod tambahan yang tidak memberikan value di single node

### 3. **Network Complexity**
- VPS biasanya hanya punya 1 IP public
- ServiceLB tidak bisa assign multiple external IPs
- Menambah kompleksitas routing tanpa benefit

## Alternatif yang Lebih Baik

### 1. **NGINX Ingress Controller**
```yaml
# Sudah include di deploy-apps.sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml
```

**Keuntungan:**
- Satu entry point untuk semua aplikasi
- Mendukung SSL/TLS termination
- Path-based dan host-based routing
- Resource usage lebih efisien

### 2. **NodePort Services**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-nodeport
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Akses via <VPS-IP>:30080
  selector:
    app: my-app
```

**Keuntungan:**
- Simple dan langsung
- Tidak butuh load balancer
- Cocok untuk development/testing

### 3. **Port Forwarding (Development)**
```bash
# Forward port ke local machine
kubectl port-forward svc/my-service 8080:80

# Akses via localhost:8080
```

## Rekomendasi untuk VPS Production

### Setup Optimal:
1. **NGINX Ingress** untuk web applications
2. **NodePort** untuk database/internal services
3. **Port forwarding** untuk debugging

### Contoh Konfigurasi:

#### Web App (Gunakan Ingress)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

#### Database (Gunakan NodePort)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-nodeport
spec:
  type: NodePort
  ports:
  - port: 5432
    targetPort: 5432
    nodePort: 30432  # Akses via <VPS-IP>:30432
  selector:
    app: postgresql
```

## Network Flow untuk VPS

```
Internet → VPS IP:80/443 → NGINX Ingress → Services → Pods
Internet → VPS IP:30XXX → NodePort Service → Pods
```

## Tips Optimasi Network

1. **Gunakan domain/subdomain** untuk aplikasi web
2. **Setup SSL/TLS** di NGINX Ingress
3. **Batasi NodePort** hanya untuk yang diperlukan
4. **Firewall rules** untuk security
