#!/bin/bash
set -euo pipefail

# Script para remoção da aplicação n8n
# MANTÉM: Base de dados PostgreSQL, Redis e dados PVC em hostPath

echo "🗑️ Removendo aplicação n8n (mantendo dados persistentes)..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo Ingress ========"
kubectl delete -f ./k8s/apps/n8n/n8n-ingress.yaml --ignore-not-found

echo "======== Removendo Certificate ========"
kubectl delete -f ./k8s/apps/n8n/n8n-certificate.yaml --ignore-not-found

echo "======== Removendo HPA ========"
kubectl delete -f ./k8s/apps/n8n/n8n-hpa.yaml --ignore-not-found

echo "======== Removendo Service ========"
kubectl delete -f ./k8s/apps/n8n/n8n-service.yaml --ignore-not-found

echo "======== Removendo Deployment n8n ========"
kubectl delete -f ./k8s/apps/n8n/n8n-deployment.yaml --ignore-not-found

echo "======== Redis e PostgreSQL mantidos (shared infrastructure) ========"
echo "  ℹ️ Redis e PostgreSQL não são removidos pois são recursos compartilhados"
echo "  📝 Para remover: cd infra/scripts && ./2.destroy-infra.sh"

echo "======== Removendo Secret n8n ========"
kubectl delete -f ./k8s/apps/n8n/n8n-secret-db.yaml --ignore-not-found

echo "======== MANTENDO PVCs n8n (dados persistentes) ========"
echo "  💾 PVCs mantidos para preservar dados em hostPath"
echo "  📁 Configurações: /home/dsm/cluster/applications/n8n/config/"
echo "  📁 Arquivos: /home/dsm/cluster/applications/n8n/files/"

echo "======== Removendo Namespace ========"
kubectl delete -f ./k8s/apps/n8n/n8n-namespace.yaml --ignore-not-found

echo ""
echo "🎉 Aplicação n8n removida!"
echo "💾 DADOS PRESERVADOS:"
echo "   �️ Database 'n8n' no PostgreSQL (workflows, credenciais)"
echo "   📁 Configurações: /home/dsm/cluster/applications/n8n/config/"
echo "   � Arquivos: /home/dsm/cluster/applications/n8n/files/"
echo "   🔄 Redis database 0 (cache)"
echo ""
echo "💡 Para recriar a aplicação:"
echo "   ./k8s/apps/n8n/scripts/3.start-n8n.sh"
echo ""
echo "🗑️ Para limpeza COMPLETA da base de dados:"
echo "   ./k8s/apps/n8n/scripts/4.drop-database-n8n.sh"
echo ""