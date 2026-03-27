#!/bin/bash
set -euo pipefail

echo "======== Criando Redis na infra ========"

# Diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "[1/4] Criando namespace redis..."
kubectl apply -f "$PROJECT_ROOT/infra/redis/redis.yaml"

echo "[2/4] Aplicando PV/PVC hostPath..."
kubectl apply -f "$PROJECT_ROOT/infra/redis/redis-pv-hostpath.yaml"
kubectl apply -f "$PROJECT_ROOT/infra/redis/redis-pvc.yaml"

echo "[3/4] Aplicando Secret..."
kubectl apply -f "$PROJECT_ROOT/infra/redis/redis-secret.yaml"

echo "[4/4] Aguardando Deployment ficar pronto..."
kubectl rollout status deployment/redis -n redis



echo ""
echo "✅ Redis criado com sucesso!"
echo ""
echo "📦 Informações do Redis:"
echo "   - Namespace: redis"
echo "   - Service: redis.redis.svc.cluster.local:6379"
echo "   - Databases disponíveis: 0-15"
echo ""
echo "🔑 Para conectar nas aplicações:"
echo "   - Host: redis.redis.svc.cluster.local"
echo "   - Port: 6379"
echo "   - Password: (definida no secret redis-secret)"
echo "   - Database: 0 (n8n), 1 (app2), etc."
echo ""