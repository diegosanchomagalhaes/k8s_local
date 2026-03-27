# Infraestrutura K3D Local

> Documentação da infraestrutura base: k3d, PostgreSQL, cert-manager e networking.

## 📋 Sumário

- [Visão Geral da Infraestrutura](#-visão-geral-da-infraestrutura)
- [Componentes](#-componentes)
- [Scripts de Infraestrutura](#-scripts-de-infraestrutura)
- [Configuração k3d](#-configuração-k3d)
- [PostgreSQL](#-postgresql)
- [Redis](#-redis)
- [cert-manager](#-cert-manager)
- [Storage Persistente](#-storage-persistente)
- [Networking](#-networking)
- [Monitoramento](#-monitoramento)
- [Troubleshooting Infraestrutura](#-troubleshooting-infraestrutura)

## 🏗 Visão Geral da Infraestrutura

A infraestrutura base é composta por:

- **k3d**: Cluster Kubernetes local leve
- **PostgreSQL**: Banco de dados persistente (StatefulSet)
- **Redis**: Cache backend para performance de aplicações
- **Traefik**: Ingress controller (padrão do k3d)
- **cert-manager**: Gerenciamento de certificados TLS self-signed
- **Storage persistente**: local-path StorageClass (automático k3d)

## 🧩 Componentes

### 🐳 k3d Cluster

- **Nome**: `k3d-cluster`
- **Configuração**: 1 server + 2 agents
- **Portas expostas**:
  - `8080:80` (HTTP)
  - `8443:443` (HTTPS)
- **Storage**: local-path (padrão k3d - automático)

### 🐘 PostgreSQL

- **Versão**: PostgreSQL 16.13
- **Namespace**: `postgres`
- **Service**: `postgres.postgres.svc.cluster.local:5432`
- **Tipo**: StatefulSet com PersistentVolumeClaim
- **Storage**: local-path StorageClass (automático k3d)
- **Recursos**:
  - CPU: 100m (request) / 500m (limit)
  - Memória: 256Mi (request) / 1Gi (limit)

### 🔴 Redis

- **Versão**: Redis 8.6.2
- **Namespace**: `redis`
- **Service**: `redis.redis.svc.cluster.local:6379`
- **Tipo**: Deployment com PersistentVolumeClaim
- **Função**: Cache backend compartilhado para todas as aplicações
- **Storage**: hostPath (`/home/dsm/cluster/redis` → `/mnt/cluster/redis`)
- **Autenticação**: Password protegido via Secret

#### **Distribuição de Databases Redis:**

| Database | Aplicação  | Uso                          | Variável de Ambiente    |
| -------- | ---------- | ---------------------------- | ----------------------- |
| **DB 0** | N8N        | Filas (Bull Queue)           | `QUEUE_BULL_REDIS_DB=0` |
| **DB 1** | Grafana    | Cache e Sessões              | `GF_DATABASE_CACHE_*`   |
| **DB 2** | GLPI       | Cache e Sessões              | `GLPI_CACHE_REDIS_DB=2` |
| **DB 3** | Prometheus | Cache de Métricas (opcional) | `REDIS_DB=3`            |

#### **Configuração por Aplicação:**

**N8N:**

```yaml
N8N_CACHE_BACKEND: redis
QUEUE_BULL_REDIS_HOST: redis.redis.svc.cluster.local
QUEUE_BULL_REDIS_PORT: 6379
QUEUE_BULL_REDIS_DB: 0 # ← Database 0
```

**Grafana:**

```yaml
GF_DATABASE_CACHE_TYPE: redis
GF_DATABASE_CACHE_CONNSTR: redis.redis.svc.cluster.local:6379?db=1 # ← Database 1
```

**GLPI:**

```yaml
GLPI_CACHE_REDIS_HOST: redis.redis.svc.cluster.local
GLPI_CACHE_REDIS_PORT: 6379
GLPI_CACHE_REDIS_DB: 2 # ← Database 2
```

### �🔐 cert-manager

- **Versão**: v1.19.0
- **Namespace**: `cert-manager`
- **Issuer**: `k3d-selfsigned` (ClusterIssuer)
- **Função**: Geração automática de certificados TLS para desenvolvimento

### 🌐 Traefik (Ingress)

- **Namespace**: `kube-system`
- **Tipo**: LoadBalancer (padrão k3d)
- **Função**: Roteamento HTTP/HTTPS e terminação TLS

## 📜 Scripts de Infraestrutura

### Scripts Principais (`infra/scripts/`)

| Script                     | Descrição                      | Componentes                             |
| -------------------------- | ------------------------------ | --------------------------------------- |
| `10.start-infra.sh`        | **Setup completo automático**  | k3d + PostgreSQL + Redis + cert-manager |
| `2.destroy-infra.sh`       | **Destruir tudo**              | Remove cluster completo                 |
| `3.create-cluster.sh`      | Criar apenas cluster           | k3d cluster                             |
| `4.delete-cluster.sh`      | Deletar cluster                | Remove k3d                              |
| `5.create-postgres.sh`     | PostgreSQL apenas              | StatefulSet + PV + Secret               |
| `6.delete-postgres.sh`     | Remover PostgreSQL             | Cleanup DB                              |
| `7.create-cert-manager.sh` | cert-manager apenas            | TLS management                          |
| `8.delete-cert-manager.sh` | Remover cert-manager           | Remove certificates                     |
| `9.setup-directories.sh`   | **Estrutura de diretórios**    | Organiza hostPath storage               |
| `11.create-redis.sh`       | Redis cache                    | Deployment + PV + Secret                |
| `12.delete-redis.sh`       | Remover Redis                  | Cleanup cache                           |
| `13.configure-hostpath.sh` | Configurar templates PV        | Templates hostPath                      |
| `14.clean-cluster-data.sh` | **Limpar dados databases**     | Drop databases PostgreSQL/MariaDB       |
| `15.clean-cluster-pvc.sh`  | **Limpar PVs/PVCs/filesystem** | Remove volumes e dados hostPath         |
| `18.destroy-all.sh`        | **Destruição completa**        | Drop DBs → Destroy → Clean filesystem   |
| `19.test-persistence.sh`   | **Testar persistência**        | Destroy cluster + manter dados          |

### Uso dos Scripts

```bash
# 🎯 Setup completo (recomendado)
./start-all.sh                        # Infra + aplicações completas
./infra/scripts/10.start-infra.sh     # Somente infraestrutura

# 🗑️ Limpeza completa
./infra/scripts/2.destroy-infra.sh    # Remove cluster + limpeza total
./infra/scripts/18.destroy-all.sh     # Drop DBs → Destroy cluster → Clean filesystem

# 🧹 Limpeza por etapas
./infra/scripts/14.clean-cluster-data.sh  # Drop databases (cluster rodando)
./infra/scripts/2.destroy-infra.sh        # Destroy cluster
./infra/scripts/15.clean-cluster-pvc.sh   # Limpar filesystem (cluster parado)

# 🧪 Teste de persistência
./infra/scripts/19.test-persistence.sh  # Testa que dados sobrevivem ao destroy

# 🔧 Componentes individuais
./infra/scripts/3.create-cluster.sh   # Somente k3d
./infra/scripts/5.create-postgres.sh  # Somente PostgreSQL
./infra/scripts/11.create-redis.sh    # Somente Redis
./infra/scripts/7.create-cert-manager.sh  # Somente cert-manager
```

## ⚙️ Configuração k3d

### Arquivo de Configuração

**Localização**: `infra/k3d/k3d-config.yaml`

```yaml
apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: k3d-cluster
servers: 1
agents: 2
ports:
  - port: 8080:80
    nodeFilters:
      - loadbalancer
  - port: 8443:443
    nodeFilters:
      - loadbalancer
volumes:
  - volume: /home/dsm/cluster:/mnt/cluster
    nodeFilters:
      - all
options:
  k3d:
    wait: true
    timeout: "60s"
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:*
  kubeconfig:
    updateDefaultKubeconfig: true
    switchCurrentContext: true
```

### Características do Cluster

- **Alta disponibilidade local**: 3 nodes (1 server + 2 agents)
- **Load balancer integrado**: Traefik automático
- **Volume compartilhado**: `/home/dsm/cluster` → `/mnt/cluster` (mapeamento hostPath)
- **Networking**: Bridge network com port forwarding

### Mapeamento de Volumes

O cluster k3d mapeia o diretório do host para dentro dos nodes:

```bash
Host:       /home/dsm/cluster/*
            ↓
Container:  /mnt/cluster/*
```

**Estrutura de Diretórios:**

```
/home/dsm/cluster/
├── postgresql/          # PostgreSQL data directory
├── redis/               # Redis persistence (RDB snapshots)
├── prometheus/          # Prometheus TSDB
├── grafana/             # Grafana dashboards e plugins
├── glpi/                # GLPI files e uploads
├── mariadb/             # MariaDB data directory
└── n8n/                 # N8N workflows e credenciais
```

**Como funciona:**

1. **k3d cria o volume**: Ao iniciar o cluster, k3d monta `/home/dsm/cluster` em todos os nodes como `/mnt/cluster`
2. **Pods acessam via hostPath**: Os Pods usam `hostPath: /mnt/cluster/<app>` nos volumes
3. **Dados persistem no host**: Como o volume aponta para o host, os dados sobrevivem ao destroy/recreate do cluster

**Exemplo de uso em PV:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/cluster/postgresql # ← Aponta para o volume mapeado no node
    type: DirectoryOrCreate
```

**Vantagens:**

- ✅ **Persistência real**: Dados sobrevivem a `k3d cluster delete`
- ✅ **Backup facilitado**: Basta copiar `/home/dsm/cluster`
- ✅ **Performance**: Acesso direto ao filesystem do host
- ✅ **Transparência**: Fácil inspecionar dados com ferramentas do host

## 🐘 PostgreSQL

### Estrutura de Arquivos

```
infra/postgres/
├── postgres-pv.yaml              # PersistentVolume
├── postgres-secret-admin.yaml    # Credenciais (não commitado)
├── postgres-secret-admin.yaml.template  # Template seguro
└── postgres.yaml                 # StatefulSet + Service
```

### Configuração do StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:16
          envFrom:
            - secretRef:
                name: postgres-admin-secret
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
```

### Storage Persistente

- **Tipo**: local-path StorageClass (padrão k3d)
- **Gerenciamento**: Automático pelo Kubernetes
- **Localização Container**: `/var/lib/postgresql/data`
- **Tamanho**: 20Gi (PVC automático)
- **Componentes com PVC**:
  - PostgreSQL: 20Gi (dados do banco)
  - Redis: 5Gi (cache persistente)
  - n8n: 10Gi (workflows e arquivos)

### Credenciais

**Template** (`postgres-secret-admin.yaml.template`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-admin-secret
type: Opaque
stringData:
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: YOUR_POSTGRES_ADMIN_PASSWORD_HERE
  POSTGRES_DB: postgres
```

## 🔐 cert-manager

### Instalação

```bash
# Aplicar manifests
kubectl apply -f infra/cert-manager/cert-manager-namespace.yaml
kubectl apply -f infra/cert-manager/cluster-issuer-selfsigned.yaml
```

### ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: k3d-selfsigned
spec:
  selfSigned: {}
```

### Uso em Aplicações

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-tls
  namespace: app-namespace
spec:
  secretName: app-tls-secret
  issuerRef:
    name: k3d-selfsigned
    kind: ClusterIssuer
  dnsNames:
    - app.local.127.0.0.1.nip.io
```

## 💾 Storage Persistente

### Configuração de Volumes

**PersistentVolume** (`postgres-pv.yaml`):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/host-k8s/postgresql/data
  persistentVolumeReclaimPolicy: Retain
```

### Backup e Restore

```bash
# Backup do banco
kubectl exec statefulset/postgres -- pg_dump -U postgres postgres > backup.sql

# Restore do banco
kubectl exec -i statefulset/postgres -- psql -U postgres postgres < backup.sql

# Backup de dados (filesystem)
# Backup do PostgreSQL (usando kubectl)
kubectl exec postgres-0 -n postgres -- pg_dumpall -U postgres > backup-$(date +%Y%m%d).sql
```

## 🌐 Networking

### Configuração de Rede

- **CNI**: Flannel (padrão k3d)
- **Service Network**: 10.43.0.0/16
- **Pod Network**: 10.42.0.0/16
- **DNS**: CoreDNS integrado

### Acesso Externo

```bash
# Port forwarding para desenvolvimento
kubectl port-forward svc/postgres 5432:5432

# Ingress via Traefik
# HTTP: http://localhost:8080
# HTTPS: https://localhost:8443
```

### DNS Interno

```yaml
# Serviços acessíveis internamente:
postgres.default.svc.cluster.local:5432
n8n.n8n.svc.cluster.local:5678
```

## 📊 Monitoramento

### Comandos Úteis

```bash
# Status geral do cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Status da infraestrutura
kubectl get statefulset postgres
kubectl get pv,pvc
kubectl get certificates --all-namespaces

# Logs da infraestrutura
kubectl logs statefulset/postgres
kubectl logs -n cert-manager deployment/cert-manager

# Recursos e performance
kubectl top nodes
kubectl top pods --all-namespaces
```

### Health Checks

```bash
# Verificar PostgreSQL
kubectl exec -it postgres-0 -- pg_isready -U postgres

# Verificar cert-manager
kubectl get certificaterequests --all-namespaces

# Verificar conectividade
kubectl run test-pod --image=postgres:16 --rm -it -- psql -h postgres.default.svc.cluster.local -U postgres
```

## 🔧 Troubleshooting Infraestrutura

### Problemas de Cluster

#### k3d não inicia

```bash
# Verificar Docker
docker ps

# Limpar e recriar
./infra/scripts/4.delete-cluster.sh
./infra/scripts/3.create-cluster.sh

# Verificar logs
docker logs k3d-k3d-cluster-server-0
```

#### Nodes não ficam Ready

```bash
# Verificar status dos nodes
kubectl get nodes -o wide

# Verificar eventos
kubectl get events --sort-by='.lastTimestamp'

# Reiniciar cluster
k3d cluster stop k3d-cluster
k3d cluster start k3d-cluster
```

### Problemas PostgreSQL

#### Pod não inicia

```bash
# Verificar status do pod
kubectl describe pod postgres-0

# Verificar logs
kubectl logs postgres-0

# Verificar volume
# Verificar status do PVC
kubectl get pvc -n postgres
kubectl describe pvc postgres-pvc -n postgres
```

#### Conexão recusada

```bash
# Verificar service
kubectl get svc postgres

# Testar conectividade interna
kubectl run test-client --image=postgres:16 --rm -it -- bash
psql -h postgres.default.svc.cluster.local -U postgres

# Port forward para teste
kubectl port-forward svc/postgres 5432:5432
```

### Problemas cert-manager

#### Certificados não são criados

```bash
# Verificar cert-manager
kubectl get pods -n cert-manager

# Verificar CertificateRequest
kubectl get certificaterequests --all-namespaces

# Verificar eventos
kubectl describe certificate -n namespace nome-cert
```

### Problemas de Storage

#### Volume não monta

```bash
# Verificar PV/PVC
kubectl get pv,pvc

# Verificar PVC e storage
kubectl get pvc -n postgres
kubectl describe pvc postgres-pvc -n postgres
kubectl get storageclass
```

#### Performance lenta

```bash
# Verificar I/O do disco
iostat -x 1

# Mover para SSD se estiver em HDD
sudo mkdir -p /mnt/nvme/postgresql
sudo chown -R 999:999 /mnt/nvme/postgresql
# Atualizar k3d-config.yaml e recriar cluster
```

---

**Infraestrutura K3D Local** - Base para Ambiente de Desenvolvimento Kubernetes  
_Última atualização: setembro 2025_
