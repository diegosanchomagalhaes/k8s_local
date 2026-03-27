#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo cert-manager ========"

# ClusterIssuer
kubectl delete -f infra/cert-manager/cluster-issuer-selfsigned.yaml --ignore-not-found

# cert-manager completo (método oficial)
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.0/cert-manager.yaml --ignore-not-found

echo "======== cert-manager removido ========"