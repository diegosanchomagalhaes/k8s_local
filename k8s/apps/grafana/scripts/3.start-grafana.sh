#!/bin/bash
set -euo pipefail

# Script para iniciar o Grafana (deploy completo)

echo "🚀 Iniciando Grafana..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

# Verificar se o arquivo de secret existe
if [ ! -f "./k8s/apps/grafana/grafana-secret-db.yaml" ]; then
    echo "❌ ERRO: Arquivo grafana-secret-db.yaml não encontrado!"
    echo ""
    echo "📝 Configure as credenciais primeiro:"
    echo "   cd $PROJECT_ROOT"
    echo "   cp k8s/apps/grafana/grafana-secret-db.yaml.template \\"
    echo "      k8s/apps/grafana/grafana-secret-db.yaml"
    echo ""
    echo "   Depois edite o arquivo e configure as credenciais do PostgreSQL"
    echo ""
    exit 1
fi

# Verificar se ainda contém placeholders
if grep -q "SENHA_POSTGRES\|USUARIO_POSTGRES\|ALTERE_ESTA_CHAVE_SECRETA" ./k8s/apps/grafana/grafana-secret-db.yaml; then
    echo "❌ ERRO: Credenciais não configuradas em grafana-secret-db.yaml"
    echo ""
    echo "📝 Edite o arquivo e substitua os placeholders por valores reais"
    echo ""
    exit 1
fi

echo "✅ Credenciais configuradas corretamente!"

# Executar deploy completo do Grafana
echo "📦 Executando deploy do Grafana..."
"$PROJECT_ROOT/k8s/apps/grafana/scripts/1.deploy-grafana.sh"

echo ""
echo "🎉 Grafana iniciado com sucesso!"
echo "📊 URL: https://grafana.local.127.0.0.1.nip.io:8443"
echo "🔑 Login: admin / admin (altere na primeira execução)"
echo ""
