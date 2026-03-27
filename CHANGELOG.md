# Changelog

Todas as mudanças notáveis neste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

---

## [Unreleased]

---

## [2.0.0] - 2025-07-17

### Segurança

- **Secrets removidos do git**: `zabbix-secret-db.yaml`, `redis-secret.yaml` e `prometheus-secret.yaml` removidos do tracking com `git rm --cached`; adicionados ao `.gitignore`
- **Prometheus BasicAuth**: novo Traefik `Middleware` (`prometheus-auth`) com autenticação básica no ingress do Prometheus; remover credenciais default antes de produção
- **Removido `--web.enable-admin-api`**: flag de administração do Prometheus eliminada por risco de segurança
- **Scripts Bash robustos**: todos os arquivos `.sh` atualizados com `set -euo pipefail` para falhar rápido em erros, variáveis não definidas e pipes com falha

### Resiliência e Alta Disponibilidade

- **PodDisruptionBudget** criado para `postgres`, `mariadb` e `redis` (`maxUnavailable: 0`) — garante disponibilidade durante drenagem de nós
- **Liveness e Readiness probes** adicionados no PostgreSQL StatefulSet (`pg_isready`)
- **`updateStrategy: RollingUpdate`** configurado em todos os StatefulSets (`postgres`, `mariadb`, `redis`)
- **Redis convertido de `Deployment` para `StatefulSet`**: garante identidade estável de pods e volumes persistentes adequados

### Observabilidade

- **Prometheus ConfigMap**: configuração `prometheus.yml` migrada de init container com heredoc para `ConfigMap` dedicado (`prometheus-configmap.yaml`); inclui Kubernetes Service Discovery com scrape de pods e services
- **Grafana DataSource ConfigMap**: datasource do Prometheus provisionado automaticamente via `grafana-datasources-configmap.yaml` montado em `/etc/grafana/provisioning/datasources`

### Isolamento de Rede

- **NetworkPolicy** criados para todos os namespaces:
  - `postgres` — permite conexões na porta 5432 de: n8n, grafana, prometheus, zabbix, glpi
  - `mariadb` — permite conexões na porta 3306 de: glpi, zabbix
  - `redis` — permite conexões na porta 6379 de: n8n, prometheus
  - `n8n` — ingress do Traefik; egress para postgres, redis e HTTPS externo
  - `grafana` — ingress do Traefik; egress para postgres e prometheus
  - `prometheus` — ingress do Traefik e grafana; egress para scraping, postgres, redis e API do k8s
  - `zabbix` — ingress do Traefik; egress para postgres, mariadb, redis e SNMP externo
  - `glpi` — ingress do Traefik; egress para mariadb e HTTPS externo

### Governança de Recursos

- **ResourceQuota** criado para todos os namespaces (limita CPU, memória, pods e PVCs):
  - `postgres`: CPU 500m/1, Mem 512Mi/2Gi, pods: 5
  - `mariadb`: CPU 500m/1, Mem 512Mi/2Gi, pods: 5
  - `redis`: CPU 200m/1, Mem 512Mi/1500Mi, pods: 5
  - `n8n`: CPU 500m/2, Mem 512Mi/2Gi, pods: 5
  - `grafana`: CPU 200m/1, Mem 512Mi/1Gi, pods: 5
  - `prometheus`: CPU 300m/2, Mem 600Mi/2Gi, pods: 5
  - `zabbix`: CPU 1/4, Mem 1Gi/4Gi, pods: 15
  - `glpi`: CPU 250m/1, Mem 256Mi/1Gi, pods: 5

### Backup

- **CronJobs de backup** criados para todas as aplicações com estado:
  - `grafana-backup-cronjob.yaml` — diário às 03:00, `pg_dump` do banco grafana, retém 7 backups
  - `prometheus-backup-cronjob.yaml` — diário às 04:00, snapshot TSDB, retém 3 backups
  - `zabbix-backup-cronjob.yaml` — diário às 02:00, `pg_dump` do banco zabbix, retém 7 backups
  - `glpi-backup-cronjob.yaml` — diário às 01:00, `mysqldump` via MariaDB, retém 7 backups

### Cloud-Readiness (Kustomize)

- **Estrutura Kustomize** criada para separar ambientes:
  - `kustomize/base/kustomization.yaml` — base única com todos os recursos
  - `kustomize/overlays/local/kustomization.yaml` — overlay local (k3d, hostPath volumes)
  - `kustomize/overlays/cloud/kustomization.yaml` — overlay cloud (StorageClass `managed`, recursos aumentados)

### Padronização

- **Labels `app.kubernetes.io/*`** padronizados em todos os objetos Kubernetes de infra (`postgres`, `mariadb`, `redis`) e apps (`prometheus`, `grafana`, `n8n`, `zabbix`, `glpi`)

---

## [1.0.0] - 2025-05-15

### Adicionado

- Estrutura inicial do projeto local com k3d
- Deploy de: PostgreSQL, MariaDB, Redis, n8n, Grafana, Prometheus, Zabbix, GLPI
- Ingress via Traefik com TLS pelo cert-manager (ClusterIssuer selfsigned)
- Scripts de automação para start/stop da infra e configuração de hosts
- PersistentVolumes com hostPath (`/home/dsm/cluster`)
- HPAs para todos os deployments de aplicação
- Pinagem de versões de todas as imagens Docker:
  - n8n `2.13.4`, Grafana `12.4.2`, Prometheus `v3.10.0`
  - GLPI `11.0.6`, Zabbix `ubuntu-7.4.8`
  - Redis `8.6.2`, MariaDB `12.2.2`, PostgreSQL `16.13`
- Branches: `main` (desenvolvimento) e `deploy-stable` (produção local)

---

## Notas de Migração

### v1.0.0 → v2.0.0

1. **Segredos**: mover os valores dos secrets para ferramentas como `kubectl create secret` ou um vault externo. Nunca commitar arquivos `*-secret.yaml` com valores reais.
2. **Prometheus BasicAuth**: alterar a senha default antes de aplicar em qualquer ambiente.  
   Gerar novo hash: `htpasswd -nb admin 'nova-senha' | base64`  
   Editar `k8s/apps/prometheus/prometheus-basicauth.yaml` com o novo valor.
3. **Redis - StatefulSet**: ao migrar de Deployment para StatefulSet, apagar o Deployment antigo antes de aplicar:  
   `kubectl delete deployment redis -n redis`
4. **Prometheus ConfigMap**: o `prometheus-config-pvc` não é mais utilizado pelo deployment. Pode ser removido se não houver dados relevantes:  
   `kubectl delete pvc prometheus-config-pvc -n prometheus`
5. **NetworkPolicies**: ao aplicar, testar conectividade entre todos os serviços antes de usar em produção. Políticas muito restritivas podem quebrar comunicações não mapeadas.
