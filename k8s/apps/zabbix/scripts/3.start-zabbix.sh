#!/bin/bash
set -euo pipefail

# Script para iniciar o Zabbix (deploy completo)

echo "🚀 Iniciando Zabbix..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

# Verificar se o arquivo de secret existe
if [ ! -f "./k8s/apps/zabbix/zabbix-secret-db.yaml" ]; then
    echo "❌ ERRO: Arquivo zabbix-secret-db.yaml não encontrado!"
    echo ""
    echo "📝 Configure as credenciais primeiro:"
    echo "   cd $PROJECT_ROOT"
    echo "   cp k8s/apps/zabbix/zabbix-secret-db.yaml.template \\"
    echo "      k8s/apps/zabbix/zabbix-secret-db.yaml"
    echo ""
    echo "   Depois edite o arquivo e configure as credenciais do PostgreSQL e Redis"
    echo ""
    exit 1
fi

# Verificar se ainda contém placeholders
if grep -q "CHANGE_ME" ./k8s/apps/zabbix/zabbix-secret-db.yaml; then
    echo "❌ ERRO: Credenciais não configuradas em zabbix-secret-db.yaml"
    echo ""
    echo "📝 Edite o arquivo e substitua os placeholders CHANGE_ME por valores reais"
    echo ""
    exit 1
fi

echo "✅ Credenciais configuradas corretamente!"

# Executar deploy completo do Zabbix
echo "📦 Executando deploy do Zabbix..."
"$PROJECT_ROOT/k8s/apps/zabbix/scripts/1.deploy-zabbix.sh"

echo ""
echo "🎉 Zabbix iniciado com sucesso!"
echo "📊 URL: https://zabbix.local.127.0.0.1.nip.io:8443"
echo "🔑 Login: Admin / zabbix (ALTERE APÓS PRIMEIRO LOGIN!)"
echo ""
