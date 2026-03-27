#!/bin/bash
set -euo pipefail

# Script para remoção da aplicação GLPI
# MANTÉM: Base de dados MariaDB, Redis e dados PVC em hostPath

echo "🗑️ Removendo aplicação GLPI (mantendo dados persistentes)..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Removendo Ingress ========"
kubectl delete -f ./k8s/apps/glpi/glpi-ingress.yaml --ignore-not-found

echo "======== [2/8] Removendo Certificate ========"
kubectl delete -f ./k8s/apps/glpi/glpi-certificate.yaml --ignore-not-found

echo "======== [3/8] Removendo HPA ========"
kubectl delete -f ./k8s/apps/glpi/glpi-hpa.yaml --ignore-not-found

echo "======== [4/8] Removendo Service ========"
kubectl delete -f ./k8s/apps/glpi/glpi-service.yaml --ignore-not-found

echo "======== [5/8] Removendo Deployment ========"
kubectl delete -f ./k8s/apps/glpi/glpi-deployment.yaml --ignore-not-found

echo "======== [6/8] Removendo PVCs (Persistent Volume Claims) ========"
kubectl delete -f ./k8s/apps/glpi/glpi-pvc.yaml --ignore-not-found

echo "======== [7/8] Removendo Secret ========"
kubectl delete -f ./k8s/apps/glpi/glpi-secret-db.yaml --ignore-not-found

echo "======== [8/8] Removendo Namespace ========"
kubectl delete namespace glpi --ignore-not-found

echo ""
echo "✅ Aplicação GLPI removida com sucesso!"
echo ""
echo "⚠️  ATENÇÃO: Os seguintes recursos foram MANTIDOS:"
echo "   → Base de dados MariaDB (database: glpi)"
echo "   → Volumes persistentes (PVs e PVCs)"
echo "   → Dados no filesystem (/home/dsm/cluster/applications/glpi/)"
echo ""
echo "📝 Para remover os volumes persistentes também, execute:"
echo "   ./6.delete-volumes-glpi.sh"
echo ""
echo "� Para remover o banco de dados, execute:"
echo "   ./4.drop-database-glpi.sh"