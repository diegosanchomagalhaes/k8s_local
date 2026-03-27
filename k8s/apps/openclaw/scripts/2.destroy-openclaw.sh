#!/bin/bash
set -euo pipefail

# Script para remoção da aplicação OpenClaw
# MANTÉM: dados de configuração e workspace nos PVCs em hostPath

echo "🗑️ Removendo aplicação OpenClaw (mantendo dados persistentes)..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo Ingress ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-ingress.yaml --ignore-not-found

echo "======== Removendo Certificate ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-certificate.yaml --ignore-not-found

echo "======== Removendo HPA ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-hpa.yaml --ignore-not-found

echo "======== Removendo NetworkPolicy ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-networkpolicy.yaml --ignore-not-found

echo "======== Removendo Service ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-service.yaml --ignore-not-found

echo "======== Removendo Deployment OpenClaw ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-deployment.yaml --ignore-not-found

echo "======== Removendo Secret ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-secret.yaml --ignore-not-found

echo "======== MANTENDO PVCs OpenClaw (dados persistentes) ========"
echo "  💾 PVCs mantidos para preservar dados em hostPath"
echo "  📁 Configuração: /mnt/cluster/applications/openclaw/config/"
echo "  📁 Workspace:    /mnt/cluster/applications/openclaw/workspace/"

echo "======== Removendo Namespace ========"
kubectl delete -f ./k8s/apps/openclaw/openclaw-namespace.yaml --ignore-not-found

echo ""
echo "🎉 Aplicação OpenClaw removida!"
echo "💾 DADOS PRESERVADOS:"
echo "   📁 Config:     /mnt/cluster/applications/openclaw/config/"
echo "   📁 Workspace:  /mnt/cluster/applications/openclaw/workspace/"
echo ""
echo "💡 Para recriar a aplicação:"
echo "   ./k8s/apps/openclaw/scripts/3.start-openclaw.sh"
echo ""
echo "🗑️ Para limpeza COMPLETA dos volumes:"
echo "   ./k8s/apps/openclaw/scripts/4.restart-openclaw.sh"
echo ""
