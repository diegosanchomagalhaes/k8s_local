#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Remoção do cert-manager
# ==============================================================================
echo "[PASB] Removendo cert-manager..."
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml --ignore-not-found
kubectl delete namespace cert-manager --ignore-not-found
echo "[PASB] cert-manager removido."
