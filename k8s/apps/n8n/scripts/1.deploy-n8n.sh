#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo ">>> [1/8] Namespace n8n..."
kubectl apply -f ./k8s/apps/n8n/n8n-namespace.yaml

echo ">>> [2/8] Secret de conexão DB + Redis..."
kubectl apply -f ./k8s/apps/n8n/n8n-secret-db.yaml

echo ">>> [3/8] Persistent Volumes..."
kubectl apply -f ./k8s/apps/n8n/n8n-pv-hostpath.yaml

echo ">>> [4/8] Persistent Volume Claims..."
kubectl apply -f ./k8s/apps/n8n/n8n-pvc.yaml

echo ">>> [5/8] Verificando dependências (PostgreSQL + Redis)..."
kubectl get pods -n postgres -l app=postgres | grep -q "Running" || \
  { echo "ERRO: PostgreSQL não está Running. Execute: infra/scripts/10.start-infra.sh"; exit 1; }
kubectl get pods -n redis -l app=redis | grep -q "Running" || \
  { echo "ERRO: Redis não está Running. Execute: infra/scripts/10.start-infra.sh"; exit 1; }
echo "  Dependências OK."

echo ">>> [6/8] TLS Certificate..."
kubectl apply -f ./k8s/apps/n8n/n8n-certificate.yaml

echo ">>> [7/8] Deployment + Service..."
kubectl apply -f ./k8s/apps/n8n/n8n-deployment.yaml
kubectl apply -f ./k8s/apps/n8n/n8n-service.yaml

echo ">>> [8/8] HPA + Ingress + NetworkPolicy + ResourceQuota..."
kubectl apply -f ./k8s/apps/n8n/n8n-hpa.yaml
kubectl apply -f ./k8s/apps/n8n/n8n-ingress.yaml
kubectl apply -f ./k8s/apps/n8n/n8n-networkpolicy.yaml
kubectl apply -f ./k8s/apps/n8n/n8n-resourcequota.yaml

echo "Aguardando n8n ficar pronto..."
kubectl rollout status deployment/n8n -n n8n --timeout=180s

echo ""
echo "n8n disponível em: https://n8n.local.127.0.0.1.nip.io"
