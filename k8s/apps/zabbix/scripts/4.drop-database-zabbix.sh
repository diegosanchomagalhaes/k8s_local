#!/bin/bash
set -euo pipefail

# Script para limpeza completa das bases de dados do Zabbix
# ATENÇÃO: Este script remove PERMANENTEMENTE todos os dados do Zabbix!

echo "🗑️ LIMPEZA COMPLETA - BASES DE DADOS ZABBIX"
echo "==========================================="
echo "⚠️  ATENÇÃO: Este script irá APAGAR PERMANENTEMENTE:"
echo "   • PostgreSQL - Database 'zabbix' (Server, Web)"
echo "   • MariaDB - Database 'zabbix_proxy' (Proxy)"
echo "   • Todos os hosts monitorados"
echo "   • Todo histórico de métricas e eventos"
echo "   • Todos os templates e itens configurados"
echo "   • Todos os triggers e alertas"
echo "   • Todos os mapas e gráficos"
echo "   • Todos os usuários e grupos"
echo "   • Todas as configurações personalizadas"
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
echo "🔍 Verificando se MariaDB está disponível..."

# Verificar se MariaDB está rodando
if ! kubectl get pods -n mariadb -l app=mariadb 2>/dev/null | grep -q "Running"; then
    echo "❌ MariaDB não está rodando no namespace 'mariadb'"
    echo "📝 Execute primeiro: ./infra/scripts/10.start-infra.sh"
    exit 1
fi

echo "✅ MariaDB disponível"

echo ""
echo "🗑️ Removendo base de dados 'zabbix' do PostgreSQL..."

# Terminar todas as conexões ativas
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'zabbix' AND pid <> pg_backend_pid();
"

# Drop da database zabbix
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS zabbix;"

echo "✅ Base de dados 'zabbix' removida do PostgreSQL!"

echo ""
echo "🗑️ Removendo base de dados 'zabbix_proxy' do MariaDB..."

# Drop da database zabbix_proxy
kubectl exec -n mariadb mariadb-0 -- mariadb -u root -pmariadb_root -e "DROP DATABASE IF EXISTS zabbix_proxy;"

echo "✅ Base de dados 'zabbix_proxy' removida do MariaDB!"

echo ""
echo "🎉 Todas as bases de dados do Zabbix foram removidas com sucesso!"
echo ""
echo "📝 Para recriar o ambiente Zabbix, execute:"
echo "   ./1.deploy-zabbix.sh"
echo ""
echo "⚠️  NOTA: O schema do banco será recriado automaticamente pelo Zabbix Server na primeira inicialização"
