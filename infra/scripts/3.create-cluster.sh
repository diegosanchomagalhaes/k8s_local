#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Criação do Cluster k3d
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K3D_CONFIG="${SCRIPT_DIR}/../k3d/k3d-config.yaml"

echo "[PASB] Criando cluster k3d..."
k3d cluster create --config "$K3D_CONFIG"
echo "[PASB] Cluster criado. Aguardando nós ficarem prontos..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s
echo "[PASB] Cluster pronto."
