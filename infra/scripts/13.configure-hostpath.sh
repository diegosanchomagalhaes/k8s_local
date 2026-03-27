#!/bin/bash
set -euo pipefail

# Script para configurar templates de PersistentVolumes com hostPath
# Substitui [CLUSTER_BASE_PATH] pelo path real configurado

echo "🔧 Configurando templates de PersistentVolumes..."

# Definir path base (pode ser personalizado)
CLUSTER_BASE_PATH="/home/dsm/cluster"

# Detectar o diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "📁 Path base configurado: $CLUSTER_BASE_PATH"
echo "📁 Projeto: $PROJECT_ROOT"

# Função para processar template
process_template() {
    local template_file="$1"
    local output_file="${template_file%.template}"
    
    if [ -f "$template_file" ]; then
        echo "   📝 Processando: $(basename "$template_file")"
        sed "s|\[CLUSTER_BASE_PATH\]|$CLUSTER_BASE_PATH|g" "$template_file" > "$output_file"
        echo "   ✅ Criado: $(basename "$output_file")"
    else
        echo "   ⚠️  Template não encontrado: $template_file"
    fi
}

echo ""
echo "🏗️ Processando templates..."

# Processar templates do PostgreSQL
echo "🐘 PostgreSQL:"
process_template "$PROJECT_ROOT/infra/postgres/postgres-pv-hostpath.yaml.template"

echo ""
echo "🔴 Redis:"
process_template "$PROJECT_ROOT/infra/redis/redis-pv-hostpath.yaml.template"

echo ""
echo "🔧 n8n:"
process_template "$PROJECT_ROOT/k8s/apps/n8n/n8n-pv-hostpath.yaml.template"

echo ""
echo "📊 Grafana:"
process_template "$PROJECT_ROOT/k8s/apps/grafana/grafana-pv-hostpath.yaml.template"

echo ""
echo "✅ Templates configurados!"
echo ""
echo "📋 Arquivos criados:"
echo "   - infra/postgres/postgres-pv-hostpath.yaml"
echo "   - infra/redis/redis-pv-hostpath.yaml" 
echo "   - k8s/apps/n8n/n8n-pv-hostpath.yaml"
echo "   - k8s/apps/grafana/grafana-pv-hostpath.yaml"
echo ""
echo "🎯 Próximos passos:"
echo "1. Execute: ./infra/scripts/9.setup-directories.sh"
echo "2. Destrua a infraestrutura atual: ./infra/scripts/2.destroy-infra.sh"
echo "3. Inicie com hostPath: ./start-all.sh"
echo ""
echo "💡 Para personalizar o path base, edite a variável CLUSTER_BASE_PATH neste script"