#!/bin/bash
set -euo pipefail

echo "======== Removendo Volumes Persistentes do OpenClaw ========"
echo ""
echo "⚠️  ATENÇÃO: Esta operação removerá TODOS os dados do OpenClaw!"
echo "⚠️  Isso inclui:"
echo "   → Configuração do Gateway (openclaw.json)"
echo "   → Credenciais de canais (WhatsApp, Telegram, Discord, etc.)"
echo "   → Token de autenticação"
echo "   → Workspace e skills"
echo "   → Histórico de sessões"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️  Parando deployment openclaw..."
kubectl scale deployment openclaw --replicas=0 -n openclaw 2>/dev/null || echo "   → Deployment openclaw não encontrado ou já parado"

echo "🗑️  Removendo PVCs (Persistent Volume Claims)..."
kubectl delete pvc openclaw-config-pvc -n openclaw 2>/dev/null || echo "   → PVC openclaw-config-pvc não encontrado"
kubectl delete pvc openclaw-workspace-pvc -n openclaw 2>/dev/null || echo "   → PVC openclaw-workspace-pvc não encontrado"

echo "🗑️  Removendo PVs (Persistent Volumes)..."
kubectl delete pv openclaw-config-pv-hostpath 2>/dev/null || echo "   → PV openclaw-config-pv-hostpath não encontrado"
kubectl delete pv openclaw-workspace-pv-hostpath 2>/dev/null || echo "   → PV openclaw-workspace-pv-hostpath não encontrado"

echo "🧹 Limpando dados no sistema de arquivos..."
sudo rm -rf /mnt/cluster/applications/openclaw/ 2>/dev/null || echo "   → Diretórios não encontrados ou já removidos"

echo ""
echo "✅ Volumes do OpenClaw removidos com sucesso!"
echo "🚀 Para recriar o ambiente: ./1.deploy-openclaw.sh"
