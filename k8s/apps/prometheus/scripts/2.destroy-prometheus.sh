#!/bin/bash
set -euo pipefail

# Script para remoção da aplicação Prometheus
# MANTÉM: Base de dados PostgreSQL, Redis e dados PVC em hostPath

echo "🗑️ Removendo aplicação Prometheus (mantendo dados persistentes)..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo Ingress ========"
kubectl delete -f ./k8s/apps/prometheus/prometheus-ingress.yaml --ignore-not-found

echo "======== Removendo Certificate ========"
kubectl delete -f ./k8s/apps/prometheus/prometheus-certificate.yaml --ignore-not-found

echo "======== Removendo HPA ========"
kubectl delete -f ./k8s/apps/prometheus/prometheus-hpa.yaml --ignore-not-found

echo "======== Removendo Service ========"
kubectl delete -f ./k8s/apps/prometheus/prometheus-service.yaml --ignore-not-found

echo "======== Removendo Deployment Prometheus ========"
kubectl delete -f ./k8s/apps/prometheus/prometheus-deployment.yaml --ignore-not-found

echo "======== Redis e PostgreSQL mantidos (shared infrastructure) ========"
echo "  ℹ️ Redis e PostgreSQL não são removidos pois são recursos compartilhados"
echo "  📝 Para remover: cd infra/scripts && ./2.destroy-infra.sh"

echo "======== Removendo Secret Prometheus ========"
kubectl delete -f ./k8s/apps/prometheus/prometheus-secret-db.yaml --ignore-not-found

echo "======== MANTENDO PVCs Prometheus (dados persistentes) ========"
echo "  💾 PVCs mantidos para preservar dados em hostPath"
echo "  📁 Dados: /home/dsm/cluster/applications/prometheus/"
echo "  📁 Configurações: /home/dsm/cluster/applications/prometheus/config/"

echo "======== MANTENDO PVs Prometheus (volumes persistentes) ========"
echo "  🏗️ PVs mantidos para permitir reconexão dos dados"
echo "  📝 Para remover volumes também: execute o script 6.delete-volumes-prometheus.sh"

echo ""
echo "🎯 Prometheus removido com sucesso!"
echo "💾 Dados preservados em /home/dsm/cluster/applications/prometheus/"
echo "🔄 Para recriar: execute ./1.deploy-prometheus.sh"