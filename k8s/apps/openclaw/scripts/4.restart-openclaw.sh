#!/bin/bash
set -euo pipefail

# Script para restart/recriar o OpenClaw mantendo dados

echo "🔄 Reiniciando OpenClaw..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/3] Parando OpenClaw (mantendo dados) ========"
kubectl delete deployment openclaw -n openclaw --ignore-not-found
kubectl delete pod -l app=openclaw -n openclaw --ignore-not-found

echo "======== [2/3] Aguardando pods terminarem ========"
kubectl wait --for=delete pod -l app=openclaw -n openclaw --timeout=120s 2>/dev/null || true

echo "======== [3/3] Recriando OpenClaw ========"
kubectl apply -f ./k8s/apps/openclaw/openclaw-deployment.yaml

echo "[INFO] Aguardando OpenClaw ficar pronto..."
kubectl rollout status deployment/openclaw -n openclaw

echo ""
echo "🦞 OpenClaw reiniciado com sucesso!"
echo "🌐 Acesse: https://openclaw.local.127.0.0.1.nip.io:8443"
echo "💾 Todos os dados e configurações foram preservados"

# Mostrar status
echo ""
echo "📋 Status dos pods:"
kubectl get pods -n openclaw -l app=openclaw

echo ""
echo "🌐 Status do serviço:"
kubectl get svc -n openclaw openclaw
