# Grafana - Monitoramento e Observabilidade

> 🔍 **Dashboards e Métricas**: Grafana v12.4.2 com PostgreSQL, TLS automático e auto-scaling para monitoramento completo da infraestrutura.

[![Grafana](https://img.shields.io/badge/Grafana-12.4.2-orange)](https://grafana.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16.13-blue)](https://www.postgresql.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.34.1-blue)](https://kubernetes.io/)
[![cert-manager](https://img.shields.io/badge/cert--manager-v1.19.0-green)](https://cert-manager.io/)

## 🎯 **Status Atual - Grafana Completo**

- ✅ **Grafana 12.4.2**: Interface web para monitoramento
- ✅ **PostgreSQL Integration**: Database dedicado 'grafana'
- ✅ **HTTPS/TLS**: Certificados automáticos via cert-manager
- ✅ **Auto-scaling**: HPA configurado (1-3 replicas)
- ✅ **hostPath Persistence**: Dados em `/home/dsm/cluster/pvc/grafana` (TRUE PaaS)
- ✅ **Separated PV/PVC**: Arquitetura limpa com PV/PVC separados
- ✅ **Security**: Secrets, non-root user, resource limits
- ✅ **DataSource ConfigMap**: Prometheus provisionado automaticamente via ConfigMap (`grafana-datasources-configmap.yaml`)
- ✅ **NetworkPolicy**: Ingress do Traefik; egress para PostgreSQL e Prometheus
- ✅ **ResourceQuota**: CPU 200m/1, Memória 512Mi/1Gi, pods: 5

## 🌐 **Acesso**

| Serviço      | URL                                           | Porta | Credenciais                            | Status |
| ------------ | --------------------------------------------- | ----- | -------------------------------------- | ------ |
| **Grafana**  | `https://grafana.local.127.0.0.1.nip.io:8443` | 8443  | admin / admin (altere na primeira vez) | ✅     |
| **Database** | `postgres.postgres.svc.cluster.local:5432`    | 5432  | (credenciais configuradas via secret)  | ✅     |
| **Internal** | `grafana.grafana.svc.cluster.local:3000`      | 3000  | (acesso interno do cluster)            | ✅     |

> ⚠️ **Porta 8443**: k3d mapeia `443→8443` para evitar privilégios root

### 🔐 **Credenciais de Acesso Padrão**

| Item            | Valor                                                         | Observação                                                  |
| --------------- | ------------------------------------------------------------- | ----------------------------------------------------------- |
| 🌐 **URL**      | `https://grafana.local.127.0.0.1.nip.io:8443`                 | Usar sempre HTTPS na porta 8443                             |
| 👤 **Usuário**  | `admin`                                                       | Usuário administrador padrão                                |
| 🔑 **Senha**    | `admin`                                                       | **⚠️ ATENÇÃO**: Grafana solicitará troca no primeiro login! |
| 💾 **Database** | PostgreSQL 16.13 (`postgres.postgres.svc.cluster.local:5432`) | Database: `grafana`                                         |
| 🗄️ **Cache**    | Redis 8.6.2 (`redis.redis.svc.cluster.local:6379`)            | Database: DB1 (cache)                                       |
| 🗄️ **Sessions** | Redis 8.6.2 (`redis.redis.svc.cluster.local:6379`)            | Database: DB1 (sessões)                                     |

> 🔒 **RECOMENDAÇÕES DE SEGURANÇA**:
>
> 1. Altere a senha padrão `admin` imediatamente no primeiro login
> 2. Configure autenticação de dois fatores (2FA) se disponível
> 3. Crie usuários separados com permissões específicas
> 4. Use senhas fortes (mínimo 16 caracteres)
> 5. Aceite o certificado self-signed no navegador

## 📋 **Sumário**

- [Deploy Rápido](#-deploy-rápido)
- [Arquitetura](#-arquitetura)
- [Configuração](#-configuração)
- [Scripts Disponíveis](#-scripts-disponíveis)
- [Storage e Backup](#-storage-e-backup)
- [Troubleshooting](#-troubleshooting)
- [Segurança](#-segurança)

## 🚀 **Deploy Rápido**

### **⚡ Setup Completo em 2 Comandos**

```bash
# 🎯 OPÇÃO 1: Deploy completo (recomendado)
./start-all.sh                        # Infra + n8n + grafana
./start-all.sh grafana                # Infra + somente grafana

# 🎯 OPÇÃO 2: Deploy manual
./infra/scripts/10.start-infra.sh     # 1. Infraestrutura base
./k8s/apps/grafana/scripts/3.start-grafana.sh  # 2. Grafana completo
```

### **🌐 Acesso Imediato**

- **Grafana**: https://grafana.local.127.0.0.1.nip.io:8443
- **Login**: `admin` / `Admin_Grafana_2025_K8s_10243769`

### **🔧 Configuração de HOSTS**

> ⚠️ **IMPORTANTE**: O domínio `grafana.local.127.0.0.1.nip.io` é automaticamente adicionado ao `/etc/hosts` durante o deploy.

**Configuração Manual (se necessário):**

```bash
# Adicionar ao /etc/hosts (Linux/WSL2)
echo "127.0.0.1 grafana.local.127.0.0.1.nip.io" | sudo tee -a /etc/hosts

# Verificar se foi adicionado
grep "grafana.local" /etc/hosts
```

**Para WSL2:**

- O script de deploy já configura automaticamente o `/etc/hosts`
- Acesse via Windows: `https://grafana.local.127.0.0.1.nip.io:8443`
- **Porta 8443**: k3d mapeia `443→8443` para evitar privilégios root

**Remover entrada (se necessário):**

```bash
sudo sed -i "/grafana.local.127.0.0.1.nip.io/d" /etc/hosts
```

---

## 🏗 **Arquitetura**

### **📦 Componentes**

```
Grafana Stack
├── 🔍 Grafana Pod              # Interface principal (port 3000)
├── 🗄️ PostgreSQL Database      # Storage de configurações e dashboards
├── 💾 PVC Storage (15Gi)       # Dados persistentes + configurações
├── 🔒 TLS Certificate          # HTTPS automático
├── 🔄 HPA Autoscaler          # 1-3 replicas baseado em CPU/RAM
└── 🌐 Traefik Ingress         # Roteamento HTTPS
```

### **🔗 Integração com Infraestrutura**

```
┌─────────────────────────────────────────────────────────┐
│                     k3d Cluster                        │
├─────────────────────────────────────────────────────────┤
│  Namespace: grafana                                     │
│  ├── 🔍 Grafana (12.4.2)                                │
│  ├── 💾 PVCs: grafana-pvc (10Gi) + grafana-data (5Gi) │
│  └── 🔐 Secrets: DB credentials + admin auth           │
├─────────────────────────────────────────────────────────┤
│  Namespace: postgres                                    │
│  └── 🗄️ PostgreSQL: Database 'grafana'                │
├─────────────────────────────────────────────────────────┤
│  Namespace: cert-manager                                │
│  └── 🔒 TLS Certificate: grafana.local.*               │
└─────────────────────────────────────────────────────────┘
```

## ⚙️ **Configuração**

### **🗄️ Database & Cache**

**PostgreSQL:**

- **Database**: `grafana`
- **User**: `grafana`
- **Host**: `postgres.postgres.svc.cluster.local:5432`
- **SSL**: Disabled (internal cluster communication)
- **Max Connections**: 300

**Redis Cache (Database 1):**

- **Host**: `redis.redis.svc.cluster.local:6379`
- **Database**: `1` (DB1 exclusively for Grafana)
- **Purpose**: Cache de sessões, configurações e queries
- **Connection**: `redis://redis.redis.svc.cluster.local:6379?db=1`

> 📝 **Redis Database**: Grafana utiliza **Redis DB1** exclusivamente para cache e sessões. Este database é separado dos outros aplicativos (n8n=DB0, GLPI=DB2, Prometheus=DB3).

### **🔐 Autenticação**

- **Admin User**: `admin`
- **Admin Password**: `Admin_Grafana_2025_K8s_10243769`
- **Secret Key**: Configurado via Secret
- **Cookie Security**: Habilitado para HTTPS

### **📊 Plugins Pré-instalados**

- `grafana-clock-panel`: Relógio nos dashboards
- `grafana-simple-json-datasource`: APIs JSON
- `grafana-worldmap-panel`: Mapas geográficos

### **🏗️ Resources**

```yaml
Resources:
  Requests: 100m CPU, 128Mi RAM
  Limits: 500m CPU, 512Mi RAM

Storage:
  Data: 10Gi (dashboards, datasources, users)
  Config: 5Gi (configurações, plugins)

HPA: 1-3 replicas (80% CPU/RAM threshold)
```

## 🛠️ **Scripts Disponíveis**

### **📁 Estrutura**

```
k8s/apps/grafana/
├── scripts/
│   ├── 1.deploy-grafana.sh      # 🚀 Deploy completo
│   ├── 2.destroy-grafana.sh     # 🗑️ Remoção completa
│   ├── 5.restart-grafana.sh     # 🔄 Restart (mantém dados)
│   └── 6.delete-volumes-grafana.sh # 🗑️ Remove PVs e PVCs para recriar
├── grafana-*.yaml               # 📄 Manifests Kubernetes
└── README.md                    # 📚 Esta documentação
```

### **🎯 Comandos Principais**

```bash
# Deploy completo (nova instalação)
./k8s/apps/grafana/scripts/1.deploy-grafana.sh

# Restart (preserva dados e configurações)
./k8s/apps/grafana/scripts/5.restart-grafana.sh

# Remoção completa (⚠️ remove todos os dados)
./k8s/apps/grafana/scripts/2.destroy-grafana.sh
```

## 💾 **Storage e Backup**

### **📂 Persistent Volumes**

- **grafana-pvc**: 10Gi (dados principais)
  - `/var/lib/grafana`: Dashboards, users, datasources
- **grafana-data-pvc**: 5Gi (configurações)
  - `/etc/grafana`: Configurações, provisioning

### **🔄 Backup Strategy**

```bash
# Database backup (configurações e dashboards)
kubectl exec -n postgres postgres-0 -- pg_dump -U grafana grafana > grafana-backup.sql

# PVC backup (via sistema de backup da infraestrutura)
./backup/backup-complete.sh  # Inclui PVCs do Grafana

# Restore database
kubectl exec -n postgres postgres-0 -- psql -U grafana grafana < grafana-backup.sql
```

## 🔧 **Troubleshooting**

### **🔍 Status e Logs**

```bash
# Status geral
kubectl get all -n grafana

# Logs do Grafana
kubectl logs -n grafana -l app=grafana -f

# Status do database
kubectl exec -n postgres postgres-0 -- psql -U postgres -c \"\\l\"

# Verificar certificados
kubectl get certificate -n grafana
```

### **❌ Problemas Comuns**

#### **1. Grafana não inicia (Database connection)**

```bash
# Verificar se database existe
kubectl exec -n postgres postgres-0 -- psql -U postgres -c \"SELECT datname FROM pg_database WHERE datname = 'grafana';\"

# Recriar database se necessário
kubectl exec -n postgres postgres-0 -- psql -U postgres -c \"CREATE DATABASE grafana;\"
kubectl exec -n postgres postgres-0 -- psql -U postgres -c \"GRANT ALL ON DATABASE grafana TO grafana;\"
```

#### **2. HTTPS não funciona**

```bash
# Verificar certificado
kubectl describe certificate grafana-tls -n grafana

# Verificar ingress
kubectl describe ingress grafana -n grafana

# Verificar hosts
grep grafana /etc/hosts
```

#### **3. Performance lenta**

```bash
# Verificar recursos
kubectl describe pod -n grafana -l app=grafana

# Verificar HPA
kubectl get hpa -n grafana

# Escalar manualmente se necessário
kubectl scale deployment grafana -n grafana --replicas=2
```

## 🛡️ **Segurança**

### **🔐 Configurações de Segurança**

- ✅ **Non-root user**: UID/GID 472
- ✅ **Resource limits**: CPU e RAM controlados
- ✅ **TLS obrigatório**: Redirect automático para HTTPS
- ✅ **Secrets**: Credenciais não expostas em plain text
- ✅ **Cookie security**: Secure cookies para HTTPS
- ✅ **Network policies**: Isolamento por namespace

### **🔑 Rotação de Credenciais**

```bash
# Atualizar senha do admin
kubectl patch secret grafana-db-secret -n grafana -p '{\"data\":{\"GF_SECURITY_ADMIN_PASSWORD\":\"NOVA_SENHA_BASE64\"}}'

# Restart para aplicar
./k8s/apps/grafana/scripts/5.restart-grafana.sh
```

### **📊 Auditoria**

```bash
# Verificar configurações de segurança
kubectl exec -n grafana -l app=grafana -- grafana-cli admin data-migration

# Logs de autenticação
kubectl logs -n grafana -l app=grafana | grep -i auth
```

---

## 🔗 **Integração com Monitoramento**

### **📈 Data Sources Recomendados**

1. **Prometheus**: Métricas do cluster Kubernetes
2. **PostgreSQL**: Métricas do banco n8n e grafana
3. **Redis**: Métricas de cache
4. **Node Exporter**: Métricas do sistema host

### **📊 Dashboards Úteis**

- **Kubernetes Cluster Overview**
- **PostgreSQL Database Monitoring**
- **Redis Cache Analytics**
- **n8n Workflow Metrics**

---

**🎯 Grafana completamente configurado e pronto para produção!**

Acesse https://grafana.local.127.0.0.1.nip.io:8443 e comece a criar seus dashboards! 📊
