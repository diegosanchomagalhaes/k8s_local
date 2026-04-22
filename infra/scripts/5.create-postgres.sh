#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Deploy do PostgreSQL (pgvector)
#  Requer: postgres-secret-admin.yaml e postgres-pv-hostpath.yaml resolvidos
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_DIR="${SCRIPT_DIR}/../postgres"

echo "[PASB] Aplicando StorageClass..."
kubectl apply -f "${SCRIPT_DIR}/../storage/hostpath-storageclass.yaml"

echo "[PASB] Aplicando manifests do PostgreSQL..."
kubectl apply -f "${POSTGRES_DIR}/postgres.yaml"
kubectl apply -f "${POSTGRES_DIR}/postgres-pv-hostpath.yaml"
kubectl apply -f "${POSTGRES_DIR}/postgres-pvc.yaml"
kubectl apply -f "${POSTGRES_DIR}/postgres-secret-admin.yaml"
kubectl apply -f "${POSTGRES_DIR}/postgres-networkpolicy.yaml"
kubectl apply -f "${POSTGRES_DIR}/postgres-resourcequota.yaml"
kubectl apply -f "${POSTGRES_DIR}/postgres-pdb.yaml"

echo "[PASB] Aguardando PostgreSQL ficar pronto..."
kubectl wait --namespace postgres \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=120s

echo "[PASB] PostgreSQL pronto."
