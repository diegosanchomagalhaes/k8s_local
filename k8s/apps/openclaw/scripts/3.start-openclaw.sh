#!/bin/bash
set -euo pipefail

# Script para iniciar o OpenClaw (deploy completo)

echo "🦞 Iniciando OpenClaw..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

# Verificar se o arquivo de secret existe
if [ ! -f "./k8s/apps/openclaw/openclaw-secret.yaml" ]; then
    echo "❌ ERRO: Arquivo openclaw-secret.yaml não encontrado!"
    echo ""
    echo "📝 Configure as credenciais primeiro:"
    echo "   cd $PROJECT_ROOT"
    echo "   cp k8s/apps/openclaw/openclaw-secret.yaml.template \\"
    echo "      k8s/apps/openclaw/openclaw-secret.yaml"
    echo ""
    echo "   Edite o arquivo e configure:"
    echo "   • OPENCLAW_GATEWAY_TOKEN  (gere com: openssl rand -hex 32)"
    echo "   • OPENAI_API_KEY ou ANTHROPIC_API_KEY"
    echo ""
    exit 1
fi

# Verificar se ainda contém placeholders
if grep -q "YOUR_OPENCLAW_GATEWAY_TOKEN_HERE" ./k8s/apps/openclaw/openclaw-secret.yaml; then
    echo "❌ ERRO: Credenciais não configuradas em openclaw-secret.yaml"
    echo ""
    echo "📝 Edite o arquivo e substitua os placeholders por valores reais"
    echo "   Gere o token com: openssl rand -hex 32"
    echo ""
    exit 1
fi

echo "✅ Credenciais configuradas corretamente!"

# Executar deploy completo do OpenClaw
echo "📦 Executando deploy do OpenClaw..."
"$PROJECT_ROOT/k8s/apps/openclaw/scripts/1.deploy-openclaw.sh"

echo ""
echo "🦞 OpenClaw iniciado com sucesso!"
echo "🌐 Control UI: https://openclaw.local.127.0.0.1.nip.io:8443"
echo "🔑 Cole o OPENCLAW_GATEWAY_TOKEN nas configurações da Control UI"
echo ""
