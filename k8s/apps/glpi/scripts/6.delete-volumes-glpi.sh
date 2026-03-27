#!/bin/bash
set -euo pipefail

echo "======== Removendo Volumes Persistentes do GLPI ========"
echo ""
echo "⚠️  ATENÇÃO: Esta operação removerá TODOS os dados do GLPI!"
echo "⚠️  Isso inclui:"
echo "   → Configurações personalizadas"
echo "   → Arquivos enviados" 
echo "   → Dados de aplicação"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️  Parando deployment glpi..."
kubectl scale deployment glpi --replicas=0 -n glpi 2>/dev/null || echo "   → Deployment glpi não encontrado ou já parado"

echo "🗑️  Removendo PVCs (Persistent Volume Claims)..."
kubectl delete pvc glpi-pvc -n glpi 2>/dev/null || echo "   → PVC glpi-pvc não encontrado"
kubectl delete pvc glpi-data-pvc -n glpi 2>/dev/null || echo "   → PVC glpi-data-pvc não encontrado"
kubectl delete pvc glpi-config-pvc -n glpi 2>/dev/null || echo "   → PVC glpi-config-pvc não encontrado"
kubectl delete pvc glpi-files-pvc -n glpi 2>/dev/null || echo "   → PVC glpi-files-pvc não encontrado"

echo "🗑️  Removendo PVs (Persistent Volumes)..."
kubectl delete pv glpi-pv-hostpath 2>/dev/null || echo "   → PV glpi-pv-hostpath não encontrado"
kubectl delete pv glpi-data-pv-hostpath 2>/dev/null || echo "   → PV glpi-data-pv-hostpath não encontrado"
kubectl delete pv glpi-config-pv-hostpath 2>/dev/null || echo "   → PV glpi-config-pv-hostpath não encontrado"
kubectl delete pv glpi-files-pv-hostpath 2>/dev/null || echo "   → PV glpi-files-pv-hostpath não encontrado"

echo "🧹 Limpando dados no sistema de arquivos..."
sudo rm -rf /home/dsm/cluster/applications/glpi/ 2>/dev/null || echo "   → Diretórios não encontrados ou já removidos"

echo ""
echo "✅ Volumes do GLPI removidos com sucesso!"
echo "📝 Para recriar o ambiente, execute: ./1.deploy-glpi.sh"