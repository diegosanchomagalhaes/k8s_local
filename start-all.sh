#!/bin/bash
set -euo pipefail

# Script de conveniência para inicializar infraestrutura + aplicações
# Para usar: ./start-all.sh [aplicacao]
# Exemplos:
#   ./start-all.sh              # Inicializa infra + todas as aplicações
#   ./start-all.sh n8n          # Inicializa infra + somente n8n
#   ./start-all.sh grafana      # Inicializa infra + somente grafana
#   ./start-all.sh prometheus   # Inicializa infra + somente prometheus
#   ./start-all.sh glpi         # Inicializa infra + somente glpi
#   ./start-all.sh zabbix       # Inicializa infra + somente zabbix
#   ./start-all.sh openclaw    # Inicializa infra + somente openclaw

echo "🚀 Iniciando ambiente completo..."

# =================================================================
# 0. DEFINIR DIRETÓRIO BASE DO PROJETO
# =================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "📁 Diretório do projeto: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Parâmetro para aplicação específica
SPECIFIC_APP="$1"

# Lista de aplicações disponíveis
AVAILABLE_APPS=("n8n" "grafana" "prometheus" "glpi" "zabbix" "openclaw")

# =================================================================
# FUNÇÃO: VERIFICAR SE APLICAÇÃO TEM DADOS PERSISTENTES
# =================================================================
has_persistent_data() {
    local app_name="$1"
    local data_dir="/home/dsm/cluster/applications/$app_name"
    
    # Verificar se o diretório existe e não está vazio
    if [ -d "$data_dir" ] && [ "$(ls -A "$data_dir" 2>/dev/null)" ]; then
        return 0  # Tem dados
    else
        return 1  # Não tem dados
    fi
}

# =================================================================
# FUNÇÃO: VERIFICAR SE APLICAÇÃO EXISTE NO CLUSTER
# =================================================================
check_app_exists() {
    local app_name="$1"
    
    # Verificar se o deployment existe no cluster
    if kubectl get deployment "$app_name" -n "$app_name" &>/dev/null; then
        return 0  # Existe
    else
        return 1  # Não existe
    fi
}

# =================================================================
# FUNÇÃO: CONFIGURAR HOSTS PARA UMA APLICAÇÃO
# =================================================================
setup_app_hosts() {
    local app_name="$1"
    local hosts_script="$PROJECT_ROOT/k8s/apps/$app_name/scripts/0.setup-hosts-$app_name.sh"
    
    if [ -f "$hosts_script" ]; then
        echo "🏠 Configurando hosts para $app_name..."
        "$hosts_script" add
        
        if [ $? -eq 0 ]; then
            echo "✅ Hosts configurado para $app_name"
            return 0
        else
            echo "⚠️  Falha ao configurar hosts para $app_name"
            return 1
        fi
    else
        echo "⚠️  Script de hosts não encontrado para $app_name: $hosts_script"
        return 0  # Não é crítico, continua mesmo sem o script
    fi
}

# =================================================================
# FUNÇÃO: DEPLOY DE UMA APLICAÇÃO
# =================================================================
deploy_single_app() {
    local app_name="$1"
    local deploy_script="$PROJECT_ROOT/k8s/apps/$app_name/scripts/1.deploy-$app_name.sh"
    
    if [ -f "$deploy_script" ]; then
        echo "📦 Fazendo deploy do $app_name..."
        cd "$PROJECT_ROOT"
        "$deploy_script"
        
        if [ $? -eq 0 ]; then
            echo "✅ $app_name deployado com sucesso!"
            return 0
        else
            echo "❌ Falha no deploy do $app_name"
            return 1
        fi
    else
        echo "⚠️  Script de deploy não encontrado para $app_name: $deploy_script"
        return 1
    fi
}

# =================================================================
# FUNÇÃO: INICIAR UMA APLICAÇÃO (COM LÓGICA DE DADOS PERSISTENTES)
# =================================================================
start_single_app() {
    local app_name="$1"
    local start_script="$PROJECT_ROOT/k8s/apps/$app_name/scripts/3.start-$app_name.sh"
    
    echo ""
    echo "🔄 Processando $app_name..."
    
    # Configurar entrada no hosts primeiro
    setup_app_hosts "$app_name"
    
    # Verificar se tem dados persistentes
    if has_persistent_data "$app_name"; then
        echo "💾 Dados persistentes encontrados para $app_name"
        
        # Se tem dados, verifica se aplicação existe no cluster
        if check_app_exists "$app_name"; then
            echo "🔄 $app_name já deployado, apenas iniciando..."
            if [ -f "$start_script" ]; then
                "$start_script"
                if [ $? -eq 0 ]; then
                    echo "✅ $app_name iniciado com dados existentes!"
                    return 0
                else
                    echo "❌ Falha ao iniciar $app_name"
                    return 1
                fi
            else
                echo "⚠️  Script de start não encontrado: $start_script"
                return 1
            fi
        else
            echo "📋 $app_name não deployado no cluster, fazendo deploy com dados existentes..."
            if deploy_single_app "$app_name"; then
                echo "✅ $app_name deployado e usando dados existentes!"
                return 0
            else
                return 1
            fi
        fi
    else
        echo "📂 Nenhum dado persistente encontrado para $app_name"
        echo "🚀 Executando deploy completo do zero..."
        
        if deploy_single_app "$app_name"; then
            echo "✅ $app_name deployado com sucesso (instalação nova)!"
            return 0
        else
            return 1
        fi
    fi
}

# =================================================================
# 1. INICIAR INFRAESTRUTURA
# =================================================================
echo "🏗️ Passo 1: Infraestrutura base..."
"$PROJECT_ROOT/infra/scripts/10.start-infra.sh"

if [ $? -ne 0 ]; then
    echo "❌ Falha na inicialização da infraestrutura"
    exit 1
fi

echo ""
echo "✅ Infraestrutura pronta!"
echo ""

# =================================================================
# 2. INICIAR APLICAÇÕES
# =================================================================
if [ -n "$SPECIFIC_APP" ]; then
    # Verificar se a aplicação específica existe na lista
    if [[ " ${AVAILABLE_APPS[@]} " =~ " ${SPECIFIC_APP} " ]]; then
        echo "📱 Passo 2: Aplicação específica ($SPECIFIC_APP)..."
        start_single_app "$SPECIFIC_APP"
    else
        echo "❌ Aplicação '$SPECIFIC_APP' não encontrada!"
        echo "📋 Aplicações disponíveis: ${AVAILABLE_APPS[*]}"
        exit 1
    fi
else
    # Iniciar todas as aplicações disponíveis
    echo "📱 Passo 2: Todas as aplicações..."
    for app in "${AVAILABLE_APPS[@]}"; do
        start_single_app "$app"
    done
fi

# =================================================================
# 3. RESUMO FINAL
# =================================================================
echo ""
echo "🎉 Ambiente completo pronto!"
echo ""
echo "📋 Componentes da infraestrutura:"
echo "   ✅ k3d cluster"
echo "   ✅ PostgreSQL"
echo "   ✅ MariaDB"
echo "   ✅ Redis"
echo "   ✅ cert-manager"
echo ""
echo "📱 Aplicações ativas:"

# Verificar quais aplicações estão rodando
for app in "${AVAILABLE_APPS[@]}"; do
    if kubectl get pods -n "$app" 2>/dev/null | grep -q "Running"; then
        case "$app" in
            "n8n")
                echo "   ✅ n8n - https://n8n.local.127.0.0.1.nip.io:8443"
                ;;
            "grafana")
                echo "   ✅ grafana - https://grafana.local.127.0.0.1.nip.io:8443"
                ;;
            "prometheus")
                echo "   ✅ prometheus - https://prometheus.local.127.0.0.1.nip.io:8443"
                ;;
            "glpi")
                echo "   ✅ glpi - https://glpi.local.127.0.0.1.nip.io:8443"
                ;;
            "zabbix")
                echo "   ✅ zabbix - https://zabbix.local.127.0.0.1.nip.io:8443"
                ;;
            "openclaw")
                echo "   ✅ openclaw - https://openclaw.local.127.0.0.1.nip.io:8443"
                ;;
            *)
                echo "   ✅ $app"
                ;;
        esac
    else
        echo "   ⏸️  $app (não rodando)"
    fi
done

echo ""
echo "💡 Para iniciar aplicações específicas:"
echo "   ./start-all.sh n8n          # Somente n8n"
echo "   ./start-all.sh grafana      # Somente grafana"
echo "   ./start-all.sh prometheus   # Somente prometheus"
echo "   ./start-all.sh glpi         # Somente glpi"
echo "   ./start-all.sh zabbix       # Somente zabbix"
echo "   ./start-all.sh openclaw    # Somente openclaw"
echo ""
echo "🔄 Comportamento inteligente:"
echo "   • Se existem dados em /home/dsm/cluster/applications/[app]/ → Preserva dados existentes"
echo "   • Se não existem dados → Deploy completo do zero"
echo "   • Dados sempre persistem entre destruições de cluster"
echo ""