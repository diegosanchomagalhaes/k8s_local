#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Deploy do Redis
#  Requer: redis-secret.yaml e redis-pv-hostpath.yaml resolvidos
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDIS_DIR="${SCRIPT_DIR}/../redis"

echo "[PASB] Aplicando manifests do Redis..."
kubectl apply -f "${REDIS_DIR}/redis.yaml"
kubectl apply -f "${REDIS_DIR}/redis-pv-hostpath.yaml"
kubectl apply -f "${REDIS_DIR}/redis-pvc.yaml"
kubectl apply -f "${REDIS_DIR}/redis-secret.yaml"
kubectl apply -f "${REDIS_DIR}/redis-networkpolicy.yaml"
kubectl apply -f "${REDIS_DIR}/redis-resourcequota.yaml"
kubectl apply -f "${REDIS_DIR}/redis-pdb.yaml"

echo "[PASB] Aguardando Redis ficar pronto..."
kubectl wait --namespace redis \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=120s

echo "[PASB] Redis pronto."
