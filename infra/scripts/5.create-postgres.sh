#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Criando PostgreSQL na infra ========"

echo "[1/4] Criando namespace postgres..."
kubectl apply -f infra/postgres/postgres.yaml

echo "[2/4] Aplicando PV hostPath..."
kubectl apply -f infra/postgres/postgres-pv-hostpath.yaml

echo "[2.5/4] Aplicando PVC..."
kubectl apply -f infra/postgres/postgres-pvc.yaml

echo "[3/4] Criando Secret admin dinamicamente..."
kubectl create secret generic postgres-admin-secret \
  --from-literal=postgres-password=postgres_admin \
  --namespace=postgres \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[4/4] Aguardando PostgreSQL ficar pronto..."
kubectl rollout status statefulset/postgres -n postgres

echo "======== PostgreSQL pronto no namespace postgres ========"
echo "Host interno: postgres.postgres.svc.cluster.local:5432"