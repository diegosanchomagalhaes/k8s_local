#!/bin/bash
set -euo pipefail

# Script para remoção da aplicação Zabbix
# MANTÉM: Base de dados PostgreSQL/MariaDB, Redis e dados PVC em hostPath

echo "🗑️ Removendo aplicação Zabbix (mantendo dados persistentes)..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/14] Removendo Ingress ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-ingress.yaml --ignore-not-found

echo "======== [2/14] Removendo Certificate ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-certificate.yaml --ignore-not-found

echo "======== [3/14] Removendo todos os HPAs (7 componentes) ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-server-hpa.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-hpa.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-proxy-hpa.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-agent2-hpa.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-agent-classic-hpa.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-java-gateway-hpa.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-web-service-hpa.yaml --ignore-not-found

echo "======== [4/14] Removendo SNMP Traps ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-snmptraps-deployment.yaml --ignore-not-found

echo "======== [5/14] Removendo Proxy ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-proxy-deployment.yaml --ignore-not-found

echo "======== [6/14] Removendo Web Service ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-web-service-deployment.yaml --ignore-not-found

echo "======== [7/14] Removendo Java Gateway ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-java-gateway-deployment.yaml --ignore-not-found

echo "======== [8/14] Removendo Agent Classic Deployment ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-agent-classic-deployment.yaml --ignore-not-found

echo "======== [9/14] Removendo Agent2 Deployment ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-agent2-deployment.yaml --ignore-not-found

echo "======== [10/14] Removendo Deployments (Server e Web) ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-web-deployment.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/zabbix/zabbix-server-deployment.yaml --ignore-not-found

echo "======== [11/14] Removendo Services ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-service.yaml --ignore-not-found

echo "======== [12/14] Removendo Secrets ========"
kubectl delete -f ./k8s/apps/zabbix/zabbix-secret-db.yaml --ignore-not-found

echo "======== MANTENDO PVCs Zabbix (dados persistentes) ========"
echo "  💾 PVCs mantidos para preservar dados em hostPath"
echo "  📁 Dados Server: /home/dsm/cluster/pvc/zabbix/server/"
echo "  📁 Dados Web: /home/dsm/cluster/pvc/zabbix/web/"
echo "  📁 Dados Proxy: /home/dsm/cluster/pvc/zabbix/proxy/"
echo "  📁 Dados SNMP Traps: /home/dsm/cluster/pvc/zabbix/snmptraps/"

echo "======== [13/14] Removendo Namespace (e todos os recursos) ========"
kubectl delete namespace zabbix --ignore-not-found

echo "======== [14/14] Limpando diretórios vazios ========"
echo "  🧹 Removendo pods órfãos..."

echo ""
echo "🎉 Aplicação Zabbix removida!"
echo "💾 DADOS PRESERVADOS:"
echo "   🗄️ PostgreSQL - Database 'zabbix' (Server, Web)"
echo "   🗄️ MariaDB - Database 'zabbix_proxy' (Proxy)"
echo "   💾 Cache Redis DB4 (sessões, dados temporários)"
echo "   📁 Volumes hostPath (logs, bibliotecas, módulos)"
echo ""
echo "⚠️  ATENÇÃO: Para remover os dados persistentes, execute:"
echo "   → Base de dados: ./4.drop-database-zabbix.sh"
echo "   → Volumes: ./6.delete-volumes-zabbix.sh"
