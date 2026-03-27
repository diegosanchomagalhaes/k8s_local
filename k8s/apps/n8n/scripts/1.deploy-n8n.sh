#!/bin/bash
set -euo pipefail

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Criando namespace do n8n ========"
kubectl apply -f ./k8s/apps/n8n/n8n-namespace.yaml

echo "======== [2/8] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/n8n/n8n-secret-db.yaml

echo "======== [3/8] Criando PVs n8n (Persistent Volumes) ========"
kubectl apply -f ./k8s/apps/n8n/n8n-pv-hostpath.yaml

echo "======== [4/8] Criando PVCs n8n (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/n8n/n8n-pvc.yaml

echo "======== [5/8] Verificando dependências (PostgreSQL + Redis) ========"
echo "  → Verificando PostgreSQL..."
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ PostgreSQL OK"

echo "  → Verificando Redis..."
if ! kubectl get pods -n redis -l app=redis 2>/dev/null | grep -q "Running"; then
    echo "❌ Redis não está rodando no namespace 'redis'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ Redis OK"

echo "======== [6/8] Criando TLS Certificate ========"
kubectl apply -f ./k8s/apps/n8n/n8n-certificate.yaml

echo "======== [7/8] Criando Deployment n8n ========"
kubectl apply -f ./k8s/apps/n8n/n8n-deployment.yaml

echo "======== [8/8] Criando Service n8n ========"
kubectl apply -f ./k8s/apps/n8n/n8n-service.yaml

echo "======== [9/9] Criando HPA e Ingress ========"
kubectl apply -f ./k8s/apps/n8n/n8n-hpa.yaml
kubectl apply -f ./k8s/apps/n8n/n8n-ingress.yaml

echo "[INFO] Aguardando n8n ficar pronto..."
kubectl rollout status deployment/n8n -n n8n

echo "======== [10/10] Configurando hosts automaticamente ========"
N8N_DOMAIN="n8n.local.127.0.0.1.nip.io"

if ! grep -q "$N8N_DOMAIN" /etc/hosts; then
    echo "[INFO] Adicionando $N8N_DOMAIN ao /etc/hosts..."
    echo "127.0.0.1 $N8N_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "[OK] Domínio $N8N_DOMAIN adicionado ao /etc/hosts"
else
    echo "[OK] Domínio $N8N_DOMAIN já configurado no /etc/hosts"
fi

echo ""
echo "======== n8n implantado com sucesso ========"
echo "🎉 Acesse: https://n8n.local.127.0.0.1.nip.io:8443"
echo "🔒 TLS/HTTPS habilitado via cert-manager"
echo "� Redis cache habilitado para performance"
echo "�📊 HPA configurado para auto-scaling"
echo ""
echo "⚠️  IMPORTANTE: Use a porta 8443 para acesso HTTPS"
echo "   Cluster k3d mapeia 443 -> 8443 no host"