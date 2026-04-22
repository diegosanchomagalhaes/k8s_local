#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Start da Infraestrutura (cluster já existente)
#  Inicia o cluster k3d e aguarda os nós ficarem prontos
# ==============================================================================
echo "[PASB] Iniciando cluster pasb-cluster..."
k3d cluster start pasb-cluster

echo "[PASB] Aguardando nós ficarem prontos..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "[PASB] Verificando pods de infra..."
kubectl get pods -n postgres
kubectl get pods -n redis
kubectl get pods -n cert-manager

echo "[PASB] Infraestrutura iniciada."
