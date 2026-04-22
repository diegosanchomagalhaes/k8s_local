# OpenClaw - Gateway de IA Pessoal

> 🦞 **Gateway de IA Pessoal**: OpenClaw com TLS automático e suporte a WebSocket para integração com múltiplos provedores de IA e canais de mensagens.

[![OpenClaw](https://img.shields.io/badge/OpenClaw-latest-blue)](https://openclaw.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-local-blue)](https://kubernetes.io/)

## 📋 Sumário

- [Visão Geral](#-visão-geral-openclaw)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração de Credenciais](#-configuração-de-credenciais)
- [Deploy OpenClaw](#-deploy-openclaw)
- [Acesso e Uso](#-acesso-e-uso)
- [Scaling e Performance](#-scaling-e-performance)
- [Backup e Restore](#-backup-e-restore)
- [Troubleshooting](#-troubleshooting-openclaw)

---

## 🎯 Visão Geral OpenClaw

**OpenClaw** é um gateway de IA pessoal que permite conectar diferentes provedores de IA (OpenAI, Anthropic, Google Gemini) e canais de mensagens (WhatsApp, Telegram, Discord, Slack) em um único ponto centralizado.

### Características do Deploy

- **Imagem**: `ghcr.io/openclaw/openclaw:latest`
- **Namespace**: `openclaw`
- **Banco de dados**: Nenhum — configuração armazenada em volume persistente
- **Persistência**: hostPath em `/mnt/cluster/applications/openclaw/`
- **Acesso**: HTTPS via Ingress (porta 8443)
- **Scaling**: HPA (1-2 réplicas)
- **Certificados**: TLS via cert-manager
- **WebSocket**: Suporte nativo via Traefik

### 🔐 Acesso à Aplicação

| Item           | Valor                                          | Observação                                    |
| -------------- | ---------------------------------------------- | --------------------------------------------- |
| 🌐 **URL**     | `https://openclaw.local.127.0.0.1.nip.io:8443` | Usar sempre HTTPS na porta 8443               |
| 🔑 **Token**   | `OPENCLAW_GATEWAY_TOKEN` (definido no secret)  | Cole o token na Control UI ao primeiro acesso |
| 📡 **Gateway** | porta `18789`                                  | Endpoint principal do gateway                 |
| 🔗 **Bridge**  | porta `18790`                                  | Endpoint de bridge para canais de mensagens   |

> ⚠️ **IMPORTANTE**:
>
> - Configure `OPENCLAW_GATEWAY_TOKEN` antes do primeiro deploy
> - A porta 8443 é necessária (k3d mapeia 443→8443)
> - Aceite o certificado self-signed no navegador

---

## 🏗 Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Namespace: openclaw                       │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  🦞 OpenClaw Gateway (latest)                        │  │
│  │     Deployment + HPA (1-2 pods)                      │  │
│  │     porta 18789 (gateway) + 18790 (bridge)           │  │
│  │                                                      │  │
│  │  📦 Volumes Persistentes                             │  │
│  │     ├── openclaw-config-pvc  (5Gi) — configuração    │  │
│  │     └── openclaw-workspace-pvc (2Gi) — workspace     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  📊 HPA: 1-2 réplicas (CPU 70%, Mem 85%)                   │
│  🔒 NetworkPolicy: egresso externo para APIs de IA          │
│  💰 ResourceQuota: CPU 100m/1, Mem 256Mi/1Gi, pods 5        │
└─────────────────────────────────────────────────────────────┘
         ↕ HTTPS/WebSocket (18789/18790)
┌──────────────────────┐
│  Traefik Ingress      │
│  + cert-manager TLS  │
└──────────────────────┘
         ↕ HTTPS :8443
┌──────────────────────────────────────────────────────────────┐
│                 Acesso Externo                               │
│  openclaw.local.127.0.0.1.nip.io:8443                       │
└──────────────────────────────────────────────────────────────┘
```

### Fluxo de Dados

```
Usuário → Traefik (8443) → OpenClaw Gateway (18789)
                               ↕ HTTPS externo
                      APIs de IA (OpenAI, Anthropic, Gemini)
                      Canais (WhatsApp, Telegram, Discord, Slack)
```

---

## 📦 Estrutura de Arquivos

```
k8s/apps/openclaw/
├── openclaw-namespace.yaml          # Namespace openclaw
├── openclaw-secret.yaml             # Credenciais (NÃO commitar com valores reais)
├── openclaw-secret.yaml.template    # Template de credenciais
├── openclaw-pv-hostpath.yaml        # PersistentVolumes (hostPath)
├── openclaw-pv-hostpath.yaml.template
├── openclaw-pvc.yaml                # PersistentVolumeClaims
├── openclaw-deployment.yaml         # Deployment OpenClaw latest
├── openclaw-service.yaml            # Service ClusterIP (18789, 18790)
├── openclaw-ingress.yaml            # Ingress HTTPS via Traefik
├── openclaw-certificate.yaml        # TLS via cert-manager
├── openclaw-hpa.yaml                # HPA (1-2 réplicas)
├── openclaw-networkpolicy.yaml      # NetworkPolicy
├── openclaw-resourcequota.yaml      # ResourceQuota
└── scripts/
    ├── 0.setup-hosts-openclaw.sh    # Configuração de /etc/hosts (nip.io, auto)
    ├── 1.deploy-openclaw.sh         # Deploy completo do zero
    ├── 2.destroy-openclaw.sh        # Remove a aplicação (mantém dados)
    ├── 3.start-openclaw.sh          # Inicia o OpenClaw (valida credenciais)
    ├── 4.restart-openclaw.sh        # Reinicia o deployment
    └── 5.delete-volumes-openclaw.sh # Remove PVCs e dados do hostPath
```

---

## ✅ Pré-requisitos

Antes de fazer o deploy do OpenClaw, certifique-se de que:

- [ ] Cluster k3d em execução (`k3d cluster list`)
- [ ] Namespace `cert-manager` ativo com ClusterIssuer `selfsigned-cluster-issuer`
- [ ] Traefik em execução (`kubectl get pods -n kube-system | grep traefik`)
- [ ] `openclaw-secret.yaml` configurado com token e API keys válidos

---

## 🔑 Configuração de Credenciais

### 1. Copiar o template

```bash
cd /home/dsm/brioit_local
cp k8s/apps/openclaw/openclaw-secret.yaml.template \
   k8s/apps/openclaw/openclaw-secret.yaml
```

### 2. Gerar o token de autenticação do Gateway

```bash
openssl rand -hex 32
```

### 3. Editar o arquivo de secret

```bash
vim k8s/apps/openclaw/openclaw-secret.yaml
```

Preencha os campos:

```yaml
stringData:
  # OBRIGATÓRIO — token de autenticação do gateway
  OPENCLAW_GATEWAY_TOKEN: "seu-token-gerado-aqui"

  # Configure pelo menos uma API key de IA
  OPENAI_API_KEY: "sk-..." # OpenAI
  ANTHROPIC_API_KEY: "sk-ant-..." # Anthropic Claude
  # GOOGLE_API_KEY: "AIza..."       # Google Gemini (opcional)
```

> ⚠️ **Segurança**: `openclaw-secret.yaml` está no `.gitignore`. Nunca commite credenciais reais.

---

## 🚀 Deploy OpenClaw

### Deploy completo (primeira vez)

```bash
cd /home/dsm/brioit_local
./k8s/apps/openclaw/scripts/1.deploy-openclaw.sh
```

O script executa:

1. Cria o namespace `openclaw`
2. Aplica o Secret com as credenciais
3. Cria os PersistentVolumes e PVCs
4. Cria os diretórios no host (`/mnt/cluster/applications/openclaw/`)
5. Aplica o Certificate TLS
6. Cria o Deployment
7. Cria o Service, HPA, Ingress, NetworkPolicy e ResourceQuota
8. Aguarda o rollout completo

### Iniciar (deploy com validação de credenciais)

```bash
./k8s/apps/openclaw/scripts/3.start-openclaw.sh
```

> Valida se o `openclaw-secret.yaml` existe e não contém placeholders antes de fazer o deploy.

### Reiniciar (sem perda de dados)

```bash
./k8s/apps/openclaw/scripts/4.restart-openclaw.sh
```

### Remover aplicação (mantém dados)

```bash
./k8s/apps/openclaw/scripts/2.destroy-openclaw.sh
```

### Remover volumes (DESTRUTIVO)

```bash
./k8s/apps/openclaw/scripts/5.delete-volumes-openclaw.sh
```

> ⚠️ Remove PVCs, PVs e os dados em `/mnt/cluster/applications/openclaw/`. Solicita confirmação digitando `SIM`.

---

## 🌐 Acesso e Uso

### URL de Acesso

```
https://openclaw.local.127.0.0.1.nip.io:8443
```

### Primeiro Acesso

1. Abra o navegador e acesse a URL acima
2. Aceite o certificado self-signed
3. Cole o `OPENCLAW_GATEWAY_TOKEN` quando solicitado pela Control UI
4. Configure os provedores de IA desejados

### Portas do Gateway

| Porta | Protocolo | Uso                             |
| ----- | --------- | ------------------------------- |
| 18789 | HTTP/WS   | Gateway principal + Control UI  |
| 18790 | TCP       | Bridge para canais de mensagens |

### Provedores de IA Suportados

| Provedor  | Variável de Ambiente | Obrigatório |
| --------- | -------------------- | ----------- |
| OpenAI    | `OPENAI_API_KEY`     | Opcional    |
| Anthropic | `ANTHROPIC_API_KEY`  | Opcional    |
| Google    | `GOOGLE_API_KEY`     | Opcional    |

> Configure pelo menos um provedor de IA para que o gateway funcione.

---

## 📊 Scaling e Performance

### HPA (Horizontal Pod Autoscaler)

```yaml
minReplicas: 1
maxReplicas: 2
cpuThreshold: 70%
memoryThreshold: 85%
```

### Recursos por Pod

| Tipo     | CPU   | Memória |
| -------- | ----- | ------- |
| Requests | 100m  | 256Mi   |
| Limits   | 1000m | 1Gi     |

### ResourceQuota do Namespace

| Recurso | Requests | Limits |
| ------- | -------- | ------ |
| CPU     | 100m     | 1      |
| Memória | 256Mi    | 1Gi    |
| Pods    | —        | 5      |
| PVCs    | —        | 3      |

---

## 💾 Backup e Restore

O OpenClaw não usa banco de dados — toda a configuração fica em volumes hostPath.

### Localização dos dados

```
/mnt/cluster/applications/openclaw/
├── config/     → openclaw.json, credenciais, configuração de canais
└── workspace/  → skills, histórico de sessões
```

### Backup manual

```bash
sudo tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz \
  /mnt/cluster/applications/openclaw/
```

### Restore

```bash
# Parar o deployment
kubectl scale deployment openclaw --replicas=0 -n openclaw

# Restaurar os dados
sudo tar -xzf openclaw-backup-YYYYMMDD.tar.gz -C /

# Reiniciar
kubectl scale deployment openclaw --replicas=1 -n openclaw
```

---

## 🔍 Troubleshooting OpenClaw

### Verificar status

```bash
# Pods
kubectl get pods -n openclaw

# Logs
kubectl logs -n openclaw -l app=openclaw --tail=50

# Describe do pod
kubectl describe pod -n openclaw -l app=openclaw

# Ingress
kubectl get ingress -n openclaw

# HPA
kubectl get hpa -n openclaw
```

### Pod em CrashLoopBackOff

```bash
kubectl logs -n openclaw -l app=openclaw --previous
```

Causas comuns:

- `openclaw-secret.yaml` não aplicado ou com valores inválidos
- Permissões incorretas nos volumes hostPath (o init container deve corrigir automaticamente)
- Diretórios em `/mnt/cluster/applications/openclaw/` não existem

### Recriar diretórios e volumes

```bash
sudo mkdir -p /mnt/cluster/applications/openclaw/config
sudo mkdir -p /mnt/cluster/applications/openclaw/workspace
sudo chown -R 1000:1000 /mnt/cluster/applications/openclaw/
```

### Token inválido / não autenticado

```bash
# Verificar secret aplicado
kubectl get secret openclaw-secret -n openclaw -o jsonpath='{.data.OPENCLAW_GATEWAY_TOKEN}' | base64 -d
```

### Erro de conexão WebSocket

```bash
# Verificar logs do Traefik
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=30 | grep openclaw
```

---

> 🦞 **OpenClaw** executando no cluster k3d local com gateway unificado para múltiplos provedores de IA e canais de mensagens.
