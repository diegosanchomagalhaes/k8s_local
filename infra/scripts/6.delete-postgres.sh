#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Remoção do PostgreSQL
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_DIR="${SCRIPT_DIR}/../postgres"

echo "[PASB] Removendo PostgreSQL..."
kubectl delete -f "${POSTGRES_DIR}/" --ignore-not-found
kubectl delete namespace postgres --ignore-not-found
echo "[PASB] PostgreSQL removido."
