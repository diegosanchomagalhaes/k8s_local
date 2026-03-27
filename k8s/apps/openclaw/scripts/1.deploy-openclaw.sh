#!/bin/bash
set -euo pipefail

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Criando namespace do OpenClaw ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-namespace.yaml

echo "======== [2/8] Criando Secret do OpenClaw ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-secret.yaml

echo "======== [3/8] Criando PVs OpenClaw (Persistent Volumes) ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-pv-hostpath.yaml

echo "======== [4/8] Criando PVCs OpenClaw (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-pvc.yaml

echo "======== [5/8] Criando diretórios no host ========"
mkdir -p /mnt/cluster/applications/openclaw/config
mkdir -p /mnt/cluster/applications/openclaw/workspace
echo "  ✅ Diretórios criados em /mnt/cluster/applications/openclaw/"

echo "======== [6/8] Criando TLS Certificate ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-certificate.yaml

echo "======== [7/8] Criando Deployment OpenClaw ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-deployment.yaml

echo "======== [8/8] Criando Service OpenClaw ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-service.yaml

echo "======== Criando HPA, Ingress, NetworkPolicy e ResourceQuota ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-hpa.yaml
kubectl apply -f ./k8s/apps/openclaw/openclaw-ingress.yaml
kubectl apply -f ./k8s/apps/openclaw/openclaw-networkpolicy.yaml
kubectl apply -f ./k8s/apps/openclaw/openclaw-resourcequota.yaml

echo "[INFO] Aguardando OpenClaw ficar pronto..."
kubectl rollout status deployment/openclaw -n openclaw

echo "======== Configurando hosts automaticamente ========"
OPENCLAW_DOMAIN="openclaw.local.127.0.0.1.nip.io"

if ! grep -q "$OPENCLAW_DOMAIN" /etc/hosts; then
    echo "[INFO] Adicionando $OPENCLAW_DOMAIN ao /etc/hosts..."
    echo "127.0.0.1 $OPENCLAW_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "[OK] Domínio $OPENCLAW_DOMAIN adicionado ao /etc/hosts"
else
    echo "[OK] Domínio $OPENCLAW_DOMAIN já configurado no /etc/hosts"
fi

echo ""
echo "======== OpenClaw implantado com sucesso ========"
echo "🦞 Acesse: https://openclaw.local.127.0.0.1.nip.io:8443"
echo "🔐 Autenticação: use o token definido em OPENCLAW_GATEWAY_TOKEN"
echo "🔒 TLS/HTTPS habilitado via cert-manager"
echo "📡 Gateway WebSocket: porta 18789"
echo "📊 HPA configurado para auto-scaling"
echo ""
echo "⚠️  IMPORTANTE: Use a porta 8443 para acesso HTTPS"
echo "   Cluster k3d mapeia 443 -> 8443 no host"
