#!/bin/bash

# Restore Completo - PostgreSQL + PVCs
# Script principal para restaurar backup completo da infraestrutura

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE_DIR="./backups"  # Local backup directory

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
RESTORE COMPLETO - POSTGRESQL + PVCs

Este script executa restore completo da infraestrutura, incluindo:
- Bases de dados PostgreSQL
- Dados dos PVCs (Persistent Volume Claims)

Uso: $0 [BACKUP_TIMESTAMP] [OPÇÕES]

ARGUMENTOS:
    BACKUP_TIMESTAMP    Timestamp do backup (YYYYMMDD_HHMMSS)
                       Use 'list' para ver backups disponíveis
                       Use 'latest' para usar backup mais recente

OPÇÕES:
    --postgresql-only   Restaurar apenas PostgreSQL
    --pvc-only         Restaurar apenas PVCs
    --pvc PVC_NAME     Restaurar apenas um PVC específico
    --database DB_NAME Restaurar apenas uma database específica
    --recreate-pvcs    Recriar PVCs (CUIDADO: apaga dados atuais)
    --force            Não pedir confirmação
    --dry-run          Simular operações sem executar
    --help             Mostrar esta ajuda

EXEMPLOS:
    $0 list                                    # Listar backups
    $0 latest                                  # Restore completo mais recente
    $0 20241224_143022                        # Restore completo específico
    $0 latest --postgresql-only               # Apenas PostgreSQL
    $0 latest --pvc-only                      # Apenas PVCs
    $0 latest --pvc postgres-pvc              # Apenas PVC específico
    $0 latest --database n8n --force          # Apenas database n8n

ATENÇÃO:
    - O restore substitui TODOS os dados
    - Use --recreate-pvcs apenas se souber o que está fazendo
    - Sempre verifique os backups antes de restaurar

EOF
}

# Verificar se scripts de restore existem
check_restore_scripts() {
    local postgresql_script="${SCRIPT_DIR}/restore-postgresql.sh"
    local pvc_script="${SCRIPT_DIR}/restore-pvc.sh"
    
    if [ ! -f "$postgresql_script" ]; then
        error "Script de restore PostgreSQL não encontrado: $postgresql_script"
        exit 1
    fi
    
    if [ ! -f "$pvc_script" ]; then
        error "Script de restore PVC não encontrado: $pvc_script"
        exit 1
    fi
    
    # Tornar scripts executáveis se necessário
    chmod +x "$postgresql_script" "$pvc_script"
    
    success "Scripts de restore verificados e configurados"
}

# Listar backups disponíveis
list_backups() {
    log "Listando backups disponíveis..."
    echo ""
    
    local pg_backups=$(find "${BACKUP_BASE_DIR}/postgresql/backup" -type d -name "20*" 2>/dev/null | sort -r)
    local app_backups=$(find "${BACKUP_BASE_DIR}/applications/backup" -type d -name "20*" 2>/dev/null | sort -r)
    
    # Combinar e ordenar timestamps únicos
    local all_timestamps=$(echo -e "$pg_backups\n$app_backups" | grep -E '/20[0-9]{6}_[0-9]{6}$' | \
        sed 's|.*/||' | sort -r | uniq)
    
    if [ -z "$all_timestamps" ]; then
        warning "Nenhum backup encontrado em ${BACKUP_BASE_DIR}"
        exit 1
    fi
    
    echo -e "${GREEN}Backups disponíveis:${NC}"
    echo ""
    
    local count=1
    for timestamp in $all_timestamps; do
        local date_formatted=$(echo "$timestamp" | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
        local pg_dir="${BACKUP_BASE_DIR}/postgresql/backup/${timestamp}"
        local pvc_dir="${BACKUP_BASE_DIR}/pvc/backup/${timestamp}"
        
        echo -e "${count}. ${GREEN}${timestamp}${NC}"
        echo -e "   Data: ${date_formatted}"
        
        # Verificar componentes disponíveis
        local components=""
        if [ -d "$pg_dir" ]; then
            local pg_files=$(find "$pg_dir" -name "*.gz" | wc -l)
            components="$components PostgreSQL(${pg_files} arquivos)"
        fi
        
        if [ -d "$pvc_dir" ]; then
            local pvc_files=$(find "$pvc_dir" -name "*.tar.gz" -o -name "*.empty" | wc -l)
            components="$components PVCs(${pvc_files} volumes)"
        fi
        
        echo -e "   Componentes: ${components:-Nenhum}"
        echo ""
        
        ((count++))
    done
}

# Obter backup mais recente
get_latest_backup() {
    local pg_backups=$(find "${BACKUP_BASE_DIR}/postgresql/backup" -type d -name "20*" 2>/dev/null)
    local pvc_backups=$(find "${BACKUP_BASE_DIR}/pvc/backup" -type d -name "20*" 2>/dev/null)
    
    local latest=$(echo -e "$pg_backups\n$pvc_backups" | grep -E '/20[0-9]{6}_[0-9]{6}$' | \
        sed 's|.*/||' | sort -r | head -1)
    
    if [ -z "$latest" ]; then
        error "Nenhum backup encontrado"
        exit 1
    fi
    
    echo "$latest"
}

# Verificar se backup existe
verify_backup() {
    local timestamp=$1
    local postgresql_only=$2
    local pvc_only=$3
    
    local pg_dir="${BACKUP_BASE_DIR}/postgresql/backup/${timestamp}"
    local pvc_dir="${BACKUP_BASE_DIR}/pvc/backup/${timestamp}"
    
    local pg_exists=false
    local pvc_exists=false
    
    if [ -d "$pg_dir" ] && [ "$(find "$pg_dir" -name "*.gz" | wc -l)" -gt 0 ]; then
        pg_exists=true
    fi
    
    if [ -d "$pvc_dir" ] && [ "$(find "$pvc_dir" -name "*.tar.gz" -o -name "*.empty" | wc -l)" -gt 0 ]; then
        pvc_exists=true
    fi
    
    # Verificar se componentes necessários existem
    if [ "$postgresql_only" != true ] && [ "$pvc_only" != true ]; then
        # Restore completo - precisa de pelo menos um componente
        if [ "$pg_exists" != true ] && [ "$pvc_exists" != true ]; then
            error "Backup não encontrado ou inválido: ${timestamp}"
            exit 1
        fi
    elif [ "$postgresql_only" = true ]; then
        if [ "$pg_exists" != true ]; then
            error "Backup PostgreSQL não encontrado: ${timestamp}"
            exit 1
        fi
    elif [ "$pvc_only" = true ]; then
        if [ "$pvc_exists" != true ]; then
            error "Backup PVC não encontrado: ${timestamp}"
            exit 1
        fi
    fi
    
    success "Backup verificado: ${timestamp}"
    
    if [ "$pg_exists" = true ]; then
        log "✅ PostgreSQL disponível"
    fi
    
    if [ "$pvc_exists" = true ]; then
        log "✅ PVCs disponíveis"
    fi
}

# Confirmar operação de restore
confirm_restore() {
    local timestamp=$1
    local postgresql_only=$2
    local pvc_only=$3
    local specific_db=$4
    local specific_pvc=$5
    local recreate_pvcs=$6
    
    echo ""
    warning "=== ATENÇÃO: OPERAÇÃO DE RESTORE COMPLETO ==="
    echo ""
    
    echo "Esta operação irá RESTAURAR dados com o backup:"
    echo "  Timestamp: ${timestamp}"
    echo ""
    
    echo "Componentes a serem restaurados:"
    if [ "$pvc_only" != true ]; then
        if [ -n "$specific_db" ]; then
            echo "  ✅ PostgreSQL - Database: ${specific_db}"
        else
            echo "  ✅ PostgreSQL - Todas as databases"
        fi
    fi
    
    if [ "$postgresql_only" != true ]; then
        if [ -n "$specific_pvc" ]; then
            echo "  ✅ PVCs - Volume: ${specific_pvc}"
        else
            echo "  ✅ PVCs - Todos os volumes"
        fi
        
        if [ "$recreate_pvcs" = true ]; then
            echo "  ⚠️  PVCs serão DELETADOS e RECRIADOS"
        fi
    fi
    
    echo ""
    warning "DADOS ATUAIS SERÃO PERDIDOS!"
    echo ""
    
    read -p "Deseja continuar? (digite 'CONFIRMAR' para prosseguir): " confirm
    
    if [ "$confirm" != "CONFIRMAR" ]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi
}

# Executar restore PostgreSQL
run_postgresql_restore() {
    local timestamp=$1
    local specific_db=$2
    local force=$3
    
    log "=== EXECUTANDO RESTORE POSTGRESQL ==="
    
    local pg_args="$timestamp"
    
    if [ -n "$specific_db" ]; then
        pg_args="$pg_args --database $specific_db"
    fi
    
    if [ "$force" = true ]; then
        pg_args="$pg_args --force"
    fi
    
    if "${SCRIPT_DIR}/restore-postgresql.sh" $pg_args; then
        success "Restore PostgreSQL concluído"
        return 0
    else
        error "Falha no restore PostgreSQL"
        return 1
    fi
}

# Executar restore PVC
run_pvc_restore() {
    local timestamp=$1
    local specific_pvc=$2
    local recreate_pvcs=$3
    local force=$4
    
    log "=== EXECUTANDO RESTORE PVC ==="
    
    local pvc_args="$timestamp"
    
    if [ -n "$specific_pvc" ]; then
        pvc_args="$pvc_args --pvc $specific_pvc"
    fi
    
    if [ "$recreate_pvcs" = true ]; then
        pvc_args="$pvc_args --recreate"
    fi
    
    if [ "$force" = true ]; then
        pvc_args="$pvc_args --force"
    fi
    
    if "${SCRIPT_DIR}/restore-pvc.sh" $pvc_args; then
        success "Restore PVC concluído"
        return 0
    else
        error "Falha no restore PVC"
        return 1
    fi
}

# Função principal
main() {
    local timestamp=""
    local postgresql_only=false
    local pvc_only=false
    local specific_pvc=""
    local specific_db=""
    local recreate_pvcs=false
    local force=false
    local dry_run=false
    
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --postgresql-only)
                postgresql_only=true
                shift
                ;;
            --pvc-only)
                pvc_only=true
                shift
                ;;
            --pvc)
                specific_pvc="$2"
                shift 2
                ;;
            --database)
                specific_db="$2"
                shift 2
                ;;
            --recreate-pvcs)
                recreate_pvcs=true
                shift
                ;;
            --force)
                force=true
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
    
    # Validações
    if [ "$postgresql_only" = true ] && [ "$pvc_only" = true ]; then
        error "Não é possível usar --postgresql-only e --pvc-only ao mesmo tempo"
        exit 1
    fi
    
    if [ -z "$timestamp" ]; then
        error "Timestamp do backup é obrigatório"
        echo ""
        show_help
        exit 1
    fi
    
    log "=== INICIANDO RESTORE COMPLETO ==="
    log "Timestamp: ${timestamp}"
    
    # Verificações iniciais
    check_restore_scripts
    verify_backup "$timestamp" "$postgresql_only" "$pvc_only"
    
    if [ "$dry_run" = true ]; then
        log "=== MODO DRY-RUN (SIMULAÇÃO) ==="
        log "Operações que seriam executadas:"
        
        if [ "$pvc_only" != true ]; then
            log "  - Restore PostgreSQL"
            if [ -n "$specific_db" ]; then
                log "    Database: $specific_db"
            fi
        fi
        
        if [ "$postgresql_only" != true ]; then
            log "  - Restore PVC"
            if [ -n "$specific_pvc" ]; then
                log "    PVC: $specific_pvc"
            fi
            if [ "$recreate_pvcs" = true ]; then
                log "    Modo: Recreate PVCs"
            fi
        fi
        
        success "Simulação concluída - nenhuma alteração foi feita"
        exit 0
    fi
    
    # Confirmação (a menos que --force seja usado)
    if [ "$force" != true ]; then
        confirm_restore "$timestamp" "$postgresql_only" "$pvc_only" "$specific_db" "$specific_pvc" "$recreate_pvcs"
    fi
    
    # Executar restores
    local postgresql_success=false
    local pvc_success=false
    
    if [ "$pvc_only" != true ]; then
        if run_postgresql_restore "$timestamp" "$specific_db" "$force"; then
            postgresql_success=true
        fi
    else
        postgresql_success=true  # Não executado, mas não é falha
    fi
    
    if [ "$postgresql_only" != true ]; then
        if run_pvc_restore "$timestamp" "$specific_pvc" "$recreate_pvcs" "$force"; then
            pvc_success=true
        fi
    else
        pvc_success=true  # Não executado, mas não é falha
    fi
    
    # Resultado final
    local total_failures=0
    
    if [ "$pvc_only" != true ] && [ "$postgresql_success" != true ]; then
        ((total_failures++))
    fi
    
    if [ "$postgresql_only" != true ] && [ "$pvc_success" != true ]; then
        ((total_failures++))
    fi
    
    echo ""
    if [ $total_failures -eq 0 ]; then
        success "=== RESTORE COMPLETO CONCLUÍDO COM SUCESSO ==="
        success "Backup restaurado: ${timestamp}"
        
        if [ "$postgresql_only" = true ]; then
            success "PostgreSQL restaurado com sucesso"
        elif [ "$pvc_only" = true ]; then
            success "PVCs restaurados com sucesso"
        else
            success "Restore completo (PostgreSQL + PVCs) executado com sucesso"
        fi
        
        exit 0
    else
        warning "=== RESTORE COMPLETO CONCLUÍDO COM ${total_failures} FALHAS ==="
        warning "Verifique os erros acima para detalhes"
        exit 1
    fi
}

# Executar função principal
main "$@"