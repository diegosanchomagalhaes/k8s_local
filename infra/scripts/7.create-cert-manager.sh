#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "⚙️  Instalando cert-manager v1.19.0..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.0/cert-manager.yaml

# Aguarda os pods ficarem prontos
echo "[INFO] Aguardando pods do cert-manager ficarem prontos..."
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager  
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

# ClusterIssuer self-signed
kubectl apply -f infra/cert-manager/cluster-issuer-selfsigned.yaml

echo "======== cert-manager instalado ========"
echo "Namespace: cert-manager"
echo "ClusterIssuer: k3d-selfsigned"