#!/bin/bash
set -euo pipefail

# Script para restart/recriar o Zabbix mantendo dados

echo "🔄 Reiniciando Zabbix..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/5] Parando componentes Zabbix (mantendo dados) ========"
kubectl delete deployment zabbix-server -n zabbix --ignore-not-found
kubectl delete deployment zabbix-web -n zabbix --ignore-not-found
kubectl delete deployment zabbix-java-gateway -n zabbix --ignore-not-found
kubectl delete deployment zabbix-web-service -n zabbix --ignore-not-found
kubectl delete deployment zabbix-agent2 -n zabbix --ignore-not-found
kubectl delete deployment zabbix-agent-classic -n zabbix --ignore-not-found
kubectl delete deployment zabbix-proxy -n zabbix --ignore-not-found
kubectl delete deployment zabbix-snmptraps -n zabbix --ignore-not-found

echo "======== [2/5] Aguardando pods terminarem ========"
kubectl wait --for=delete pod -l app=zabbix -n zabbix --timeout=120s 2>/dev/null || true

echo "======== [3/5] Recriando Zabbix Server ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-server-deployment.yaml
echo "[INFO] Aguardando Zabbix Server ficar pronto..."
kubectl rollout status deployment/zabbix-server -n zabbix --timeout=300s

echo "======== [4/5] Recriando Zabbix Web ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-web-deployment.yaml
echo "[INFO] Aguardando Zabbix Web ficar pronto..."
kubectl rollout status deployment/zabbix-web -n zabbix --timeout=180s

echo "======== [5/5] Recriando componentes auxiliares + HPAs ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-server-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-proxy-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent2-deployment.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent2-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent-classic-deployment.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent-classic-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-java-gateway-deployment.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-java-gateway-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-web-service-deployment.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-web-service-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-proxy-deployment.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-snmptraps-deployment.yaml

echo ""
echo "🎉 Zabbix reiniciado com sucesso!"
echo "📊 Acesse: https://zabbix.local.127.0.0.1.nip.io:8443"
echo "💾 Todos os dados e configurações foram preservados"
echo "⚡ 7 HPAs reconfigurados para auto-scaling"

# Mostrar status
echo ""
echo "📋 Status dos pods:"
kubectl get pods -n zabbix -l app=zabbix

echo ""
echo "🌐 Status dos serviços:"
kubectl get svc -n zabbix
