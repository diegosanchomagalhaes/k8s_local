#!/bin/bash
set -euo pipefail

echo "======== Removendo Volumes Persistentes do Zabbix ========"
echo ""
echo "⚠️  ATENÇÃO: Esta operação removerá TODOS os dados locais do Zabbix!"
echo "⚠️  Isso inclui:"
echo "   → Arquivos de log do servidor"
echo "   → Bibliotecas MIB SNMP customizadas"
echo "   → Módulos web personalizados"
echo "   → Dados de aplicação local"
echo "   → Dados do Proxy"
echo "   → Dados do SNMP Traps"
echo ""
echo "📝 NOTA: Os dados dos bancos PostgreSQL/MariaDB NÃO serão removidos"
echo "   Para remover também os bancos, execute: ./4.drop-database-zabbix.sh"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️  Parando deployments zabbix..."
kubectl scale deployment zabbix-server --replicas=0 -n zabbix 2>/dev/null || echo "   → Deployment zabbix-server não encontrado ou já parado"
kubectl scale deployment zabbix-web --replicas=0 -n zabbix 2>/dev/null || echo "   → Deployment zabbix-web não encontrado ou já parado"
kubectl scale deployment zabbix-proxy --replicas=0 -n zabbix 2>/dev/null || echo "   → Deployment zabbix-proxy não encontrado ou já parado"
kubectl scale deployment zabbix-snmptraps --replicas=0 -n zabbix 2>/dev/null || echo "   → Deployment zabbix-snmptraps não encontrado ou já parado"

echo "🗑️  Removendo PVCs (Persistent Volume Claims)..."
kubectl delete pvc zabbix-server-pvc -n zabbix 2>/dev/null || echo "   → PVC zabbix-server-pvc não encontrado"
kubectl delete pvc zabbix-web-pvc -n zabbix 2>/dev/null || echo "   → PVC zabbix-web-pvc não encontrado"
kubectl delete pvc zabbix-proxy-pvc -n zabbix 2>/dev/null || echo "   → PVC zabbix-proxy-pvc não encontrado"
kubectl delete pvc zabbix-snmptraps-pvc -n zabbix 2>/dev/null || echo "   → PVC zabbix-snmptraps-pvc não encontrado"

echo "🗑️  Removendo PVs (Persistent Volumes)..."
kubectl delete pv zabbix-server-pv 2>/dev/null || echo "   → PV zabbix-server-pv não encontrado"
kubectl delete pv zabbix-web-pv 2>/dev/null || echo "   → PV zabbix-web-pv não encontrado"
kubectl delete pv zabbix-proxy-pv 2>/dev/null || echo "   → PV zabbix-proxy-pv não encontrado"
kubectl delete pv zabbix-snmptraps-pv 2>/dev/null || echo "   → PV zabbix-snmptraps-pv não encontrado"

echo "🧹 Limpando dados no sistema de arquivos..."
sudo rm -rf /home/dsm/cluster/pvc/zabbix/ 2>/dev/null || echo "   → Diretórios não encontrados ou já removidos"

echo ""
echo "✅ Volumes do Zabbix removidos com sucesso!"
echo "📝 Para recriar o ambiente, execute: ./1.deploy-zabbix.sh"
echo ""
echo "⚠️  LEMBRE-SE: Os dados do PostgreSQL/MariaDB foram preservados"
echo "   Para limpar também os bancos, execute: ./4.drop-database-zabbix.sh"
