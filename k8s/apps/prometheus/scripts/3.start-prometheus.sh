#!/bin/bash
set -euo pipefail

# Script para iniciar o Prometheus (deploy completo)

echo "🚀 Iniciando Prometheus..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

# Verificar se o arquivo de secret existe
if [ ! -f "./k8s/apps/prometheus/prometheus-secret-db.yaml" ]; then
    echo "❌ ERRO: Arquivo prometheus-secret-db.yaml não encontrado!"
    echo ""
    echo "📝 Configure as credenciais primeiro:"
    echo "   cd $PROJECT_ROOT"
    echo "   cp k8s/apps/prometheus/prometheus-secret-db.yaml.template \\"
    echo "      k8s/apps/prometheus/prometheus-secret-db.yaml"
    echo ""
    echo "   Depois edite o arquivo e configure as credenciais do PostgreSQL"
    echo ""
    exit 1
fi

# Verificar se ainda contém placeholders
if grep -q "YOUR_POSTGRES_ADMIN_PASSWORD_HERE" ./k8s/apps/prometheus/prometheus-secret-db.yaml; then
    echo "❌ ERRO: Credenciais não configuradas em prometheus-secret-db.yaml"
    echo ""
    echo "📝 Edite o arquivo e substitua os placeholders por valores reais"
    echo ""
    exit 1
fi

echo "✅ Credenciais configuradas corretamente!"

# Executar deploy completo do Prometheus
echo "📦 Executando deploy do Prometheus..."
"$PROJECT_ROOT/k8s/apps/prometheus/scripts/1.deploy-prometheus.sh"

echo ""
echo "🎉 Prometheus iniciado com sucesso!"
echo "🌐 Acesso: https://prometheus.local.127.0.0.1.nip.io:8443"