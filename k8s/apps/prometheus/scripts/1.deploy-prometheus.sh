#!/bin/bash
set -euo pipefail

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Criando namespace do Prometheus ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-namespace.yaml

echo "======== [2/8] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-secret-db.yaml

echo "======== [3/8] Criando PVs Prometheus (Persistent Volumes) ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-pv-hostpath.yaml

echo "======== [4/8] Criando PVCs Prometheus (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-pvc.yaml

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
kubectl apply -f ./k8s/apps/prometheus/prometheus-certificate.yaml

echo "======== [7/8] Criando Service Prometheus ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-service.yaml

echo "======== [8/8] Criando Deployment Prometheus ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-deployment.yaml

echo "======== [9/9] Criando HPA e Ingress ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-hpa.yaml
kubectl apply -f ./k8s/apps/prometheus/prometheus-ingress.yaml

echo "[INFO] Aguardando Prometheus ficar pronto..."
kubectl rollout status deployment/prometheus -n prometheus

echo "======== [10/10] Configurando hosts automaticamente ========"
PROMETHEUS_DOMAIN="prometheus.local.127.0.0.1.nip.io"

if ! grep -q "$PROMETHEUS_DOMAIN" /etc/hosts; then
    echo "[INFO] Adicionando $PROMETHEUS_DOMAIN ao /etc/hosts..."
    echo "127.0.0.1 $PROMETHEUS_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "[OK] Domínio $PROMETHEUS_DOMAIN adicionado ao /etc/hosts"
else
    echo "[OK] Domínio $PROMETHEUS_DOMAIN já configurado no /etc/hosts"
fi

echo ""
echo "======== Prometheus implantado com sucesso ========"
echo "🎉 Acesse: https://prometheus.local.127.0.0.1.nip.io:8443"
echo "🔒 TLS/HTTPS habilitado via cert-manager"
echo "⚡ Redis cache habilitado para performance"
echo "📊 HPA configurado para auto-scaling"
echo "📈 Configuração Kubernetes auto-discovery habilitada"
echo ""
echo "⚠️  IMPORTANTE: Use a porta 8443 para acesso HTTPS"
echo "   Cluster k3d mapeia 443 -> 8443 no host"