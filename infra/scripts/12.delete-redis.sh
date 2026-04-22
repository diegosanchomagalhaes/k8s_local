#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Remoção do Redis
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDIS_DIR="${SCRIPT_DIR}/../redis"

echo "[PASB] Removendo Redis..."
kubectl delete -f "${REDIS_DIR}/" --ignore-not-found
kubectl delete namespace redis --ignore-not-found
echo "[PASB] Redis removido."
