#!/bin/bash
set -euo pipefail

# Script para limpeza completa da base de dados do Grafana
# ATENÇÃO: Este script remove PERMANENTEMENTE todos os dados do Grafana!

echo "🗑️ LIMPEZA COMPLETA - BASE DE DADOS GRAFANA"
echo "==========================================="
echo "⚠️  ATENÇÃO: Este script irá APAGAR PERMANENTEMENTE:"
echo "   • Todos os dashboards do Grafana"
echo "   • Todas as configurações de data sources"
echo "   • Todos os usuários e organizações"
echo "   • Todas as configurações personalizadas"
echo "   • Todo histórico de alertas"
echo ""

# Solicitar confirmação
read -p "Tem certeza que deseja continuar? (digite 'CONFIRMAR' para prosseguir): " confirmation

if [ "$confirmation" != "CONFIRMAR" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 1
fi

echo ""
echo "🔍 Verificando se PostgreSQL está disponível..."

# Verificar se PostgreSQL está rodando
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute primeiro: ./infra/scripts/10.start-infra.sh"
    exit 1
fi

echo "✅ PostgreSQL disponível"

echo ""
echo "🗑️ Removendo base de dados 'grafana'..."

# Drop da database grafana
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'grafana' AND pid <> pg_backend_pid();
"

kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS grafana;"

echo "✅ Base de dados 'grafana' removida com sucesso!"

echo ""
echo "🔄 Recriando base de dados 'grafana' vazia..."

# Recriar database vazia
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE grafana;"

echo "✅ Base de dados 'grafana' recriada (vazia)"

echo ""
echo "🎉 Limpeza da base de dados Grafana concluída!"
echo ""
echo "💡 Próximos passos:"
echo "   • Se o Grafana estiver rodando, reinicie-o para aplicar as mudanças:"
echo "     ./k8s/apps/grafana/scripts/3.start-grafana.sh"
echo "   • Todos os dashboards e configurações precisarão ser recriados"
echo "   • Login volta a ser: admin / admin"
echo ""