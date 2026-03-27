#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "[INFO] Criando cluster k3d usando infra/k3d/k3d-config.yaml..."
k3d cluster create --config infra/k3d/k3d-config.yaml
echo "[INFO] Cluster criado. Verifique com: kubectl get nodes"