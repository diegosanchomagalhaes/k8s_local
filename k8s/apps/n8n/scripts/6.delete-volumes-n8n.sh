#!/bin/bash
set -euo pipefail

echo "======== Removendo Volumes Persistentes do n8n ========"
echo ""
echo "⚠️  ATENÇÃO: Esta operação removerá TODOS os dados do n8n!"
echo "⚠️  Isso inclui:"
echo "   → Configurações personalizadas"
echo "   → Workflows criados"
echo "   → Credenciais salvas"
echo "   → Dados de aplicação"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️  Parando deployment n8n..."
kubectl scale deployment n8n --replicas=0 -n n8n 2>/dev/null || echo "   → Deployment n8n não encontrado ou já parado"

echo "🗑️  Removendo PVCs (Persistent Volume Claims)..."
kubectl delete pvc n8n-pvc -n n8n 2>/dev/null || echo "   → PVC n8n-pvc não encontrado"
kubectl delete pvc n8n-data-pvc -n n8n 2>/dev/null || echo "   → PVC n8n-data-pvc não encontrado"

echo "🗑️  Removendo PVs (Persistent Volumes)..."
kubectl delete pv n8n-pv-hostpath 2>/dev/null || echo "   → PV n8n-pv-hostpath não encontrado"
kubectl delete pv n8n-data-pv-hostpath 2>/dev/null || echo "   → PV n8n-data-pv-hostpath não encontrado"

echo "🧹 Limpando dados no sistema de arquivos..."
sudo rm -rf /home/dsm/cluster/applications/n8n/ 2>/dev/null || echo "   → Diretórios não encontrados ou já removidos"

echo ""
echo "✅ Volumes do n8n removidos com sucesso!"
echo "� Para recriar o ambiente, execute: ./1.deploy-n8n.sh"