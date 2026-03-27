#!/bin/bash
set -euo pipefail

echo "======== Removendo Volumes Persistentes do Prometheus ========"
echo ""
echo "⚠️  ATENÇÃO: Esta operação removerá TODOS os dados do Prometheus!"
echo "⚠️  Isso inclui:"
echo "   → Métricas históricas coletadas"
echo "   → Configurações de scraping"
echo "   → Regras de alertas"
echo "   → Dados de aplicação"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️  Parando deployment prometheus..."
kubectl scale deployment prometheus --replicas=0 -n prometheus 2>/dev/null || echo "   → Deployment prometheus não encontrado ou já parado"

echo "🗑️  Removendo PVCs (Persistent Volume Claims)..."
kubectl delete pvc prometheus-pvc -n prometheus 2>/dev/null || echo "   → PVC prometheus-pvc não encontrado"
kubectl delete pvc prometheus-config-pvc -n prometheus 2>/dev/null || echo "   → PVC prometheus-config-pvc não encontrado"

echo "🗑️  Removendo PVs (Persistent Volumes)..."
kubectl delete pv prometheus-pv-hostpath 2>/dev/null || echo "   → PV prometheus-pv-hostpath não encontrado"
kubectl delete pv prometheus-config-pv-hostpath 2>/dev/null || echo "   → PV prometheus-config-pv-hostpath não encontrado"

echo "🧹 Limpando dados no sistema de arquivos..."
sudo rm -rf /home/dsm/cluster/applications/prometheus/ 2>/dev/null || echo "   → Diretórios não encontrados ou já removidos"

echo ""
echo "✅ Volumes do Prometheus removidos com sucesso!"
echo "� Para recriar o ambiente, execute: ./1.deploy-prometheus.sh"