#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo PostgreSQL da infra ========"

echo "[1/3] Removendo StatefulSet + Service..."
kubectl delete -f infra/postgres/postgres.yaml --ignore-not-found

echo "[2/3] Removendo Secret admin..."
kubectl delete -f infra/postgres/postgres-secret-admin.yaml --ignore-not-found

echo "[3/3] Removendo PV/PVC..."
kubectl delete -f infra/postgres/postgres-pv-hostpath.yaml --ignore-not-found
kubectl delete -f infra/postgres/postgres-pvc.yaml --ignore-not-found

echo "======== PostgreSQL removido ========"