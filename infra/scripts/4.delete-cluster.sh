#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Remoção do Cluster k3d
# ==============================================================================
echo "[PASB] Removendo cluster k3d pasb-cluster..."
k3d cluster delete pasb-cluster
echo "[PASB] Cluster removido."
