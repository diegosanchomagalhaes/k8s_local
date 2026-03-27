# 🔐 Segurança - Configuração de Secrets e Credenciais

## 🔐 Configuração Necessária Após Clone

Após clonar este repositório, você precisa configurar as credenciais para **todas as aplicações e infraestrutura**.

### 1. **PostgreSQL Admin Password** (infraestrutura compartilhada)

```bash
# 1. Copiar template do PostgreSQL
cp infra/postgres/postgres-secret-admin.yaml.template \
   infra/postgres/postgres-secret-admin.yaml

# 2. Editar e substituir YOUR_POSTGRES_ADMIN_PASSWORD_HERE
nano infra/postgres/postgres-secret-admin.yaml
```

**Usado por**: PostgreSQL (databases: n8n, grafana, prometheus)

### 2. **MariaDB Admin Password** (banco GLPI)

```bash
# 1. Copiar template do MariaDB
cp infra/mariadb/mariadb-secret-admin.yaml.template \
   infra/mariadb/mariadb-secret-admin.yaml

# 2. Editar e substituir YOUR_MARIADB_ROOT_PASSWORD_HERE
nano infra/mariadb/mariadb-secret-admin.yaml
```

**Usado por**: MariaDB (database: glpi)

### 3. **Redis Password** (cache compartilhado)

```bash
# 1. Copiar template do Redis
cp infra/redis/redis-secret.yaml.template \
   infra/redis/redis-secret.yaml

# 2. Editar e substituir YOUR_REDIS_PASSWORD_HERE
nano infra/redis/redis-secret.yaml
```

**Usado por**: Redis (DB0=n8n, DB1=grafana, DB2=glpi, DB3=prometheus)

### 4. **n8n Database Secret**

```bash
# 1. Copiar template do n8n
cp k8s/apps/n8n/n8n-secret-db.yaml.template \
   k8s/apps/n8n/n8n-secret-db.yaml

# 2. Editar e substituir:
#    - YOUR_POSTGRES_ADMIN_PASSWORD_HERE (mesma senha do PostgreSQL)
#    - YOUR_REDIS_PASSWORD_HERE (mesma senha do Redis)
nano k8s/apps/n8n/n8n-secret-db.yaml
```

### 5. **Grafana Database Secret**

```bash
# 1. Copiar template do Grafana
cp k8s/apps/grafana/grafana-secret-db.yaml.template \
   k8s/apps/grafana/grafana-secret-db.yaml

# 2. Editar e substituir:
#    - YOUR_POSTGRES_ADMIN_PASSWORD_HERE (mesma senha do PostgreSQL)
#    - YOUR_REDIS_PASSWORD_HERE (mesma senha do Redis)
nano k8s/apps/grafana/grafana-secret-db.yaml
```

### 6. **Prometheus Database Secret**

```bash
# 1. Copiar template do Prometheus
cp k8s/apps/prometheus/prometheus-secret-db.yaml.template \
   k8s/apps/prometheus/prometheus-secret-db.yaml

# 2. Editar e substituir:
#    - YOUR_POSTGRES_ADMIN_PASSWORD_HERE (mesma senha do PostgreSQL)
#    - YOUR_REDIS_PASSWORD_HERE (mesma senha do Redis)
nano k8s/apps/prometheus/prometheus-secret-db.yaml
```

### 7. **GLPI Database Secret**

```bash
# 1. Copiar template do GLPI
cp k8s/apps/glpi/glpi-secret-db.yaml.template \
   k8s/apps/glpi/glpi-secret-db.yaml

# 2. Editar e substituir:
#    - YOUR_MARIADB_ROOT_PASSWORD_HERE (mesma senha do MariaDB)
#    - YOUR_REDIS_PASSWORD_HERE (mesma senha do Redis)
nano k8s/apps/glpi/glpi-secret-db.yaml
```

**⚠️ IMPORTANTE:**

- Use a **MESMA senha PostgreSQL** nos secrets de n8n, grafana e prometheus
- Use a **MESMA senha MariaDB** no secret do glpi
- Use a **MESMA senha Redis** em TODOS os secrets de aplicações

### 8. **Sugestão de Senhas Seguras**

```bash
# Gerar senhas seguras:
echo "PostgreSQL: $(openssl rand -base64 24)"
echo "MariaDB: $(openssl rand -base64 24)"
echo "Redis: $(openssl rand -base64 24)"
```

### 9. **Script Automatizado (opcional)**

```bash
# Copiar TODOS os templates de uma vez
find . -name "*.yaml.template" -exec sh -c 'cp "$1" "${1%.template}"' _ {} \;

# Depois edite cada arquivo manualmente para substituir as senhas
```

### 10. **Verificar Configuração**

```bash
# Verificar se os templates foram copiados (infraestrutura)
ls -la infra/postgres/postgres-secret-admin.yaml
ls -la infra/mariadb/mariadb-secret-admin.yaml
ls -la infra/redis/redis-secret.yaml

# Verificar se os templates foram copiados (aplicações)
ls -la k8s/apps/n8n/n8n-secret-db.yaml
ls -la k8s/apps/grafana/grafana-secret-db.yaml
ls -la k8s/apps/prometheus/prometheus-secret-db.yaml
ls -la k8s/apps/glpi/glpi-secret-db.yaml

# Verificar se as senhas foram substituídas
grep -r "YOUR_.*_PASSWORD_HERE" \
  infra/postgres/ \
  infra/mariadb/ \
  infra/redis/ \
  k8s/apps/*/
# NÃO deve retornar nada se tudo foi configurado corretamente
```

### 11. **Inicializar Ambiente**

Após configurar TODAS as senhas:

```bash
# Executar deploy completo
./start-all.sh
```

## 🚫 **O que NÃO commitar:**

- `postgres-secret-admin.yaml` (com senhas)
- `mariadb-secret-admin.yaml` (com senhas)
- `redis-secret.yaml` (com senhas)
- `n8n-secret-db.yaml` (com senhas)
- `grafana-secret-db.yaml` (com senhas)
- `prometheus-secret-db.yaml` (com senhas)
- `glpi-secret-db.yaml` (com senhas)
- `*-pv-hostpath.yaml` (com paths específicos)
- Qualquer arquivo com credenciais reais

## ✅ **O que commitar:**

- `*.template` (templates sem senhas)
- Scripts de configuração
- Documentação
- Manifestos Kubernetes (sem secrets)

## 🔒 **Segurança:**

- **Nunca** commite senhas reais no Git
- **Sempre** use templates para repositórios públicos
- **Configure** `.gitignore` corretamente
- **Gere** senhas seguras para produção

---

## 🛡️ Melhorias de Segurança (v2.0.0)

### Secrets Removidos do Git

Os seguintes arquivos foram removidos do tracking do Git (não rastreados mais):

```bash
# Removidos com git rm --cached
infra/redis/redis-secret.yaml
k8s/apps/prometheus/prometheus-secret-db.yaml
k8s/apps/zabbix/zabbix-secret-db.yaml
```

Todos os padrões de secrets já estão protegidos no `.gitignore`.

### BasicAuth no Prometheus

O Prometheus agora possui autenticação básica via **Traefik Middleware**. A configuração está em `k8s/apps/prometheus/prometheus-basicauth.yaml`.

**Alterar senha padrão antes de usar:**

```bash
# Gerar hash bcrypt da nova senha
htpasswd -nb admin 'nova-senha-segura' | base64

# Editar o secret no arquivo
nano k8s/apps/prometheus/prometheus-basicauth.yaml
# Substituir o valor em data.users com o hash gerado

# Aplicar
kubectl apply -f k8s/apps/prometheus/prometheus-basicauth.yaml
```

> ⚠️ A senha padrão (`prometheus-admin`) deve ser alterada **antes** de usar em qualquer ambiente.

### NetworkPolicy — Isolamento de Rede

Todos os namespaces possuem `NetworkPolicy` que restringe o tráfego de entrada e saída:

| Namespace    | Ingress permitido                             | Egress permitido                        |
| ------------ | --------------------------------------------- | --------------------------------------- |
| `postgres`   | n8n, grafana, prometheus, zabbix, glpi (5432) | DNS (kube-system)                       |
| `mariadb`    | glpi, zabbix (3306)                           | DNS (kube-system)                       |
| `redis`      | n8n, prometheus (6379)                        | DNS (kube-system)                       |
| `n8n`        | kube-system/Traefik                           | postgres, redis, HTTPS externo          |
| `grafana`    | kube-system/Traefik                           | postgres, prometheus                    |
| `prometheus` | kube-system/Traefik, grafana                  | postgres, redis, k8s API, scraping, DNS |
| `zabbix`     | kube-system/Traefik                           | postgres, mariadb, redis, SNMP, DNS     |
| `glpi`       | kube-system/Traefik                           | mariadb, HTTPS externo, DNS             |

> ⚠️ Antes de aplicar NetworkPolicies em produção, valide todas as comunicações entre serviços.

### Remoção de Admin API do Prometheus

A flag `--web.enable-admin-api` foi removida do deployment do Prometheus. Essa flag expunha endpoints administrativos que poderiam ser usados para deletar dados ou snapshot do TSDB sem autenticação adicional.
