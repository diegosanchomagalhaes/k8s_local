#!/bin/bash

# Restore PostgreSQL Databases
# Restaura backup das bases de dados PostgreSQL usando kubectl

set -euo pipefail

# Configurações
NAMESPACE="postgres"
POSTGRES_POD="postgres-0"
BACKUP_BASE_DIR="./backups/postgresql"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
RESTORE POSTGRESQL DATABASES

Uso: $0 [BACKUP_TIMESTAMP] [OPÇÕES]

ARGUMENTOS:
    BACKUP_TIMESTAMP    Timestamp do backup a ser restaurado (formato: YYYYMMDD_HHMMSS)
                       Use 'list' para ver backups disponíveis
                       Use 'latest' para usar o backup mais recente

OPÇÕES:
    --database DB_NAME  Restaurar apenas uma database específica
    --force            Não pedir confirmação antes de restaurar
    --dry-run          Mostrar o que seria feito sem executar
    --help             Mostrar esta ajuda

EXEMPLOS:
    $0 list                                    # Listar backups disponíveis
    $0 latest                                  # Restaurar backup mais recente
    $0 20241224_143022                        # Restaurar backup específico
    $0 20241224_143022 --database n8n         # Restaurar apenas database n8n
    $0 latest --force                         # Restaurar sem confirmação

CONFIGURAÇÕES:
    Namespace: ${NAMESPACE}
    Pod PostgreSQL: ${POSTGRES_POD}
    Diretório de backup: ${BACKUP_BASE_DIR}

EOF
}

# Verificar se kubectl está disponível
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl não está instalado ou não está no PATH"
        exit 1
    fi
}

# Verificar se o pod PostgreSQL está rodando
check_postgres_pod() {
    log "Verificando se o pod PostgreSQL está rodando..."
    
    if ! kubectl get pod ${POSTGRES_POD} -n ${NAMESPACE} &> /dev/null; then
        error "Pod PostgreSQL ${POSTGRES_POD} não encontrado no namespace ${NAMESPACE}"
        exit 1
    fi
    
    local pod_status=$(kubectl get pod ${POSTGRES_POD} -n ${NAMESPACE} -o jsonpath='{.status.phase}')
    if [ "$pod_status" != "Running" ]; then
        error "Pod PostgreSQL não está em execução. Status: ${pod_status}"
        exit 1
    fi
    
    success "Pod PostgreSQL está rodando"
}

# Listar backups disponíveis
list_backups() {
    log "Backups disponíveis em ${BACKUP_BASE_DIR}:"
    echo ""
    
    if [ ! -d "${BACKUP_BASE_DIR}" ]; then
        error "Diretório de backup não existe: ${BACKUP_BASE_DIR}"
        exit 1
    fi
    
    local backups=$(find "${BACKUP_BASE_DIR}" -type d -name "20*" | sort -r)
    
    if [ -z "$backups" ]; then
        warning "Nenhum backup encontrado"
        exit 1
    fi
    
    local count=1
    for backup_dir in $backups; do
        local timestamp=$(basename "$backup_dir")
        local date_formatted=$(echo "$timestamp" | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
        local info_file="${backup_dir}/backup_info.txt"
        local file_count=$(find "$backup_dir" -name "*.gz" | wc -l)
        
        echo -e "${count}. ${GREEN}${timestamp}${NC}"
        echo -e "   Data: ${date_formatted}"
        echo -e "   Arquivos: ${file_count} backups compactados"
        
        if [ -f "$info_file" ]; then
            echo -e "   Localização: ${backup_dir}"
        else
            echo -e "   ${YELLOW}Aviso: Arquivo de informações não encontrado${NC}"
        fi
        echo ""
        
        ((count++))
    done
}

# Obter o backup mais recente
get_latest_backup() {
    local latest=$(find "${BACKUP_BASE_DIR}" -type d -name "20*" | sort -r | head -1)
    
    if [ -z "$latest" ]; then
        error "Nenhum backup encontrado"
        exit 1
    fi
    
    basename "$latest"
}

# Verificar se backup existe
verify_backup() {
    local timestamp=$1
    local backup_dir="${BACKUP_BASE_DIR}/${timestamp}"
    
    if [ ! -d "$backup_dir" ]; then
        error "Backup não encontrado: ${backup_dir}"
        exit 1
    fi
    
    local backup_files=$(find "$backup_dir" -name "*.sql.gz" | wc -l)
    if [ "$backup_files" -eq 0 ]; then
        error "Nenhum arquivo de backup encontrado em: ${backup_dir}"
        exit 1
    fi
    
    success "Backup verificado: ${timestamp} (${backup_files} arquivos)"
    echo "$backup_dir"
}

# Confirmar operação
confirm_restore() {
    local timestamp=$1
    local specific_db=$2
    
    echo ""
    warning "=== ATENÇÃO: OPERAÇÃO DE RESTORE ==="
    echo ""
    
    if [ -n "$specific_db" ]; then
        echo "Esta operação irá RESTAURAR a database '${specific_db}' com o backup:"
    else
        echo "Esta operação irá RESTAURAR TODAS as databases com o backup:"
    fi
    
    echo "  Timestamp: ${timestamp}"
    echo "  Diretório: ${BACKUP_BASE_DIR}/${timestamp}"
    echo ""
    
    warning "DADOS ATUAIS SERÃO PERDIDOS!"
    echo ""
    
    read -p "Deseja continuar? (digite 'CONFIRMAR' para prosseguir): " confirm
    
    if [ "$confirm" != "CONFIRMAR" ]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi
}

# Restaurar objetos globais
restore_globals() {
    local backup_dir=$1
    local globals_file="${backup_dir}/globals_*.sql.gz"
    
    # Verificar se arquivo de globais existe
    local globals_path=$(ls ${globals_file} 2>/dev/null | head -1)
    
    if [ -n "$globals_path" ]; then
        log "Restaurando objetos globais..."
        
        if zcat "$globals_path" | kubectl exec -i ${POSTGRES_POD} -n ${NAMESPACE} -- \
            psql -U postgres -d postgres; then
            success "Objetos globais restaurados"
        else
            warning "Falha ao restaurar objetos globais (continuando...)"
        fi
    else
        warning "Arquivo de objetos globais não encontrado"
    fi
}

# Restaurar uma database específica
restore_database() {
    local backup_dir=$1
    local db_name=$2
    local backup_file="${backup_dir}/${db_name}_*.sql.gz"
    
    # Encontrar arquivo de backup da database
    local backup_path=$(ls ${backup_file} 2>/dev/null | head -1)
    
    if [ -z "$backup_path" ]; then
        error "Arquivo de backup não encontrado para database: ${db_name}"
        return 1
    fi
    
    log "Restaurando database: ${db_name}"
    
    # Criar database se não existir
    kubectl exec ${POSTGRES_POD} -n ${NAMESPACE} -- \
        psql -U postgres -c "CREATE DATABASE ${db_name};" 2>/dev/null || true
    
    # Restaurar database
    if zcat "$backup_path" | kubectl exec -i ${POSTGRES_POD} -n ${NAMESPACE} -- \
        psql -U postgres -d ${db_name}; then
        success "Database ${db_name} restaurada"
        return 0
    else
        error "Falha ao restaurar database: ${db_name}"
        return 1
    fi
}

# Restaurar todas as databases
restore_all_databases() {
    local backup_dir=$1
    local failed_restores=0
    
    # Primeiro, restaurar objetos globais
    restore_globals "$backup_dir"
    
    # Obter lista de arquivos de backup de databases
    local backup_files=$(find "$backup_dir" -name "*_*.sql.gz" ! -name "globals_*")
    
    if [ -z "$backup_files" ]; then
        error "Nenhum arquivo de backup de database encontrado"
        exit 1
    fi
    
    # Restaurar cada database
    for backup_file in $backup_files; do
        local filename=$(basename "$backup_file")
        local db_name=$(echo "$filename" | sed 's/_[0-9]\{8\}_[0-9]\{6\}\.sql\.gz$//')
        
        if ! restore_database "$backup_dir" "$db_name"; then
            ((failed_restores++))
        fi
    done
    
    return $failed_restores
}

# Função principal
main() {
    local timestamp=""
    local specific_database=""
    local force_restore=false
    local dry_run=false
    
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --database)
                specific_database="$2"
                shift 2
                ;;
            --force)
                force_restore=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            list)
                list_backups
                exit 0
                ;;
            latest)
                timestamp=$(get_latest_backup)
                shift
                ;;
            20[0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9])
                timestamp="$1"
                shift
                ;;
            *)
                error "Argumento desconhecido: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar se timestamp foi fornecido
    if [ -z "$timestamp" ]; then
        error "Timestamp do backup é obrigatório"
        echo ""
        show_help
        exit 1
    fi
    
    log "=== INICIANDO RESTORE POSTGRESQL ==="
    
    check_kubectl
    check_postgres_pod
    
    # Verificar backup
    local backup_dir=$(verify_backup "$timestamp")
    
    if [ "$dry_run" = true ]; then
        log "=== MODO DRY-RUN (SIMULAÇÃO) ==="
        log "Timestamp: ${timestamp}"
        log "Diretório: ${backup_dir}"
        
        if [ -n "$specific_database" ]; then
            log "Database específica: ${specific_database}"
        else
            log "Todas as databases serão restauradas"
        fi
        
        log "Arquivos de backup encontrados:"
        find "$backup_dir" -name "*.sql.gz" -exec basename {} \;
        
        success "Simulação concluída - nenhuma alteração foi feita"
        exit 0
    fi
    
    # Confirmação (a menos que --force seja usado)
    if [ "$force_restore" = false ]; then
        confirm_restore "$timestamp" "$specific_database"
    fi
    
    # Executar restore
    local failed_restores=0
    
    if [ -n "$specific_database" ]; then
        # Restore de database específica
        restore_globals "$backup_dir"
        if ! restore_database "$backup_dir" "$specific_database"; then
            failed_restores=1
        fi
    else
        # Restore de todas as databases
        failed_restores=$(restore_all_databases "$backup_dir")
    fi
    
    # Resultado final
    if [ $failed_restores -eq 0 ]; then
        success "=== RESTORE POSTGRESQL CONCLUÍDO COM SUCESSO ==="
        if [ -n "$specific_database" ]; then
            success "Database restaurada: ${specific_database}"
        else
            success "Todas as databases foram restauradas"
        fi
        success "Backup usado: ${timestamp}"
    else
        warning "=== RESTORE POSTGRESQL CONCLUÍDO COM ${failed_restores} FALHAS ==="
        warning "Verifique os logs acima para detalhes"
        exit 1
    fi
}

# Executar função principal
main "$@"