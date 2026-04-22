#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Bootstrap Completo da Infraestrutura
#  Ordem: dirs → cluster → storage → cert-manager → postgres → redis
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================"
echo "  PASB — Criação da Infraestrutura"
echo "================================================================"

echo ""
echo ">>> [1/6] Setup de diretórios do host..."
bash "${SCRIPT_DIR}/9.setup-directories.sh"

echo ""
echo ">>> [2/6] Criando cluster k3d..."
bash "${SCRIPT_DIR}/3.create-cluster.sh"

echo ""
echo ">>> [3/6] Aplicando StorageClass..."
kubectl apply -f "${SCRIPT_DIR}/../storage/hostpath-storageclass.yaml"

echo ""
echo ">>> [4/6] Instalando cert-manager..."
bash "${SCRIPT_DIR}/7.create-cert-manager.sh"

echo ""
echo ">>> [5/6] Deploy do PostgreSQL..."
bash "${SCRIPT_DIR}/5.create-postgres.sh"

echo ""
echo ">>> [6/6] Deploy do Redis..."
bash "${SCRIPT_DIR}/11.create-redis.sh"

echo ""
echo "================================================================"
echo "  PASB — Infraestrutura pronta!"
echo "  Próximo passo: deploy das aplicações via k8s/apps/<app>/scripts/"
echo "================================================================"
