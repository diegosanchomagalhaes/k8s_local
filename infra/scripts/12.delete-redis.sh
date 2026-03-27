#!/bin/bash
set -euo pipefail

echo "======== Removendo Redis da infra ========"

# Diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "[1/3] Removendo Deployment e Service..."
kubectl delete -f "$PROJECT_ROOT/infra/redis/redis.yaml" --ignore-not-found=true

echo "[2/3] Removendo Secret..."
kubectl delete -f "$PROJECT_ROOT/infra/redis/redis-secret.yaml" --ignore-not-found=true

echo "[3/3] Removendo PV/PVC..."
kubectl delete -f "$PROJECT_ROOT/infra/redis/redis-pv-hostpath.yaml" --ignore-not-found=true
kubectl delete -f "$PROJECT_ROOT/infra/redis/redis-pvc.yaml" --ignore-not-found=true

echo ""
echo "✅ Redis removido com sucesso!"
echo ""