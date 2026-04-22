#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Instalação do cert-manager
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[PASB] Instalando cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
echo "[PASB] Aguardando cert-manager ficar pronto..."
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s

echo "[PASB] Aplicando ClusterIssuer selfsigned..."
kubectl apply -f "${SCRIPT_DIR}/../cert-manager/cluster-issuer-selfsigned.yaml"
echo "[PASB] cert-manager pronto."
