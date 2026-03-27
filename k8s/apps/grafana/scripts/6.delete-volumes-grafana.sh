#!/bin/bash
set -euo pipefail

echo "======== Removendo Volumes Persistentes do Grafana ========"
echo ""
echo "⚠️  ATENÇÃO: Esta operação removerá TODOS os dados do Grafana!"
echo "⚠️  Isso inclui:"
echo "   → Dashboards personalizados"
echo "   → Data sources configuradas"
echo "   → Alertas e notificações"
echo "   → Usuários e permissões"
echo "   → Dados de aplicação"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️  Parando deployment grafana..."
kubectl scale deployment grafana --replicas=0 -n grafana 2>/dev/null || echo "   → Deployment grafana não encontrado ou já parado"

echo "🗑️  Removendo PVCs (Persistent Volume Claims)..."
kubectl delete pvc grafana-pvc -n grafana 2>/dev/null || echo "   → PVC grafana-pvc não encontrado"
kubectl delete pvc grafana-data-pvc -n grafana 2>/dev/null || echo "   → PVC grafana-data-pvc não encontrado"

echo "🗑️  Removendo PVs (Persistent Volumes)..."
kubectl delete pv grafana-pv-hostpath 2>/dev/null || echo "   → PV grafana-pv-hostpath não encontrado"
kubectl delete pv grafana-data-pv-hostpath 2>/dev/null || echo "   → PV grafana-data-pv-hostpath não encontrado"

echo "🧹 Limpando dados no sistema de arquivos..."
sudo rm -rf /home/dsm/cluster/applications/grafana/ 2>/dev/null || echo "   → Diretórios não encontrados ou já removidos"

echo ""
echo "✅ Volumes do Grafana removidos com sucesso!"
echo "� Para recriar o ambiente, execute: ./1.deploy-grafana.sh"