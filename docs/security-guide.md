# 🔒 Security Guide untuk Repository

## ⚠️ PENTING: Sebelum Push ke GitHub Public

Repository ini berisi template untuk infrastruktur K3s. Pastikan langkah-langkah berikut sudah dilakukan sebelum push ke public:

## 🔐 Checklist Keamanan

### ✅ Password & Secrets
- [x] Password PostgreSQL sudah diganti ke placeholder
- [x] Tidak ada API keys atau tokens hardcoded
- [x] Tidak ada private keys atau certificates

### 📋 Yang Perlu Dilakukan Setelah Clone:

#### 1. **Update Password PostgreSQL**
```bash
# Generate password baru
NEW_PASSWORD="your-secure-password"
ENCODED_PASSWORD=$(echo -n "$NEW_PASSWORD" | base64)

# Update di apps/postgresql/deployment.yaml
sed -i "s/Y2hhbmdlbWUxMjM=/$ENCODED_PASSWORD/" apps/postgresql/deployment.yaml
```

#### 2. **Setup Secret Management (Recommended)**
Untuk production, gunakan salah satu:
- **Kubernetes Secrets dengan encryption at rest**
- **External Secret Operator** (ESO)
- **Sealed Secrets**
- **Vault** atau secret management lainnya

#### 3. **Update .gitignore**
Pastikan file-file sensitif tidak ter-commit:
```bash
# Tambahkan ke .gitignore jika belum ada
echo "secrets/" >> .gitignore
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore
echo ".env" >> .gitignore
```

## 🛡️ Best Practices Security

### 1. **Jangan Hardcode Secrets**
❌ **JANGAN:**
```yaml
env:
- name: DB_PASSWORD
  value: "mypassword123"
```

✅ **GUNAKAN:**
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

### 2. **Use Strong Passwords**
```bash
# Generate strong password
openssl rand -base64 32

# Atau gunakan tools seperti:
pwgen -s 20 1
```

### 3. **Rotate Secrets Regularly**
- Update password database minimal 3-6 bulan sekali
- Monitor akses dan usage patterns
- Audit logs secara berkala

## 🔄 Migration dari Hardcoded ke Secret Management

### Option 1: Kubernetes Native Secrets
```bash
# Create secret dari command line
kubectl create secret generic postgresql-secret \
  --from-literal=postgresql-password="your-secure-password" \
  --namespace apps
```

### Option 2: External Secret Operator
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
```

## 📊 Security Monitoring

Setelah deploy, monitor:
- Failed login attempts ke database
- Unusual access patterns
- Resource usage anomalies

## 🚨 Incident Response

Jika terjadi security breach:
1. **Immediately rotate** semua passwords/secrets
2. **Audit logs** untuk mencari akses yang mencurigakan
3. **Update** semua dependencies
4. **Review** access controls dan permissions
