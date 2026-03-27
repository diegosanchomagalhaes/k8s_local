#!/bin/bash
set -euo pipefail

# Script para restart/recriar o Prometheus mantendo dados

echo "🔄 Reiniciando Prometheus..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/3] Parando Prometheus (mantendo dados) ========"
kubectl delete deployment prometheus -n prometheus --ignore-not-found
kubectl delete pod -l app=prometheus -n prometheus --ignore-not-found

echo "======== [2/3] Aguardando pods terminarem ========"
kubectl wait --for=delete pod -l app=prometheus -n prometheus --timeout=120s 2>/dev/null || true

echo "======== [3/3] Recriando Prometheus ========"
kubectl apply -f ./k8s/apps/prometheus/prometheus-deployment.yaml

echo "[INFO] Aguardando Prometheus ficar pronto..."
kubectl rollout status deployment/prometheus -n prometheus

echo ""
echo "🎉 Prometheus reiniciado com sucesso!"
echo "🌐 Acesse: https://prometheus.local.127.0.0.1.nip.io:8443"
echo "💾 Todos os dados e configurações foram preservados"