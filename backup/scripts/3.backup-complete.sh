#!/bin/bash

# Backup Completo - PostgreSQL + PVCs
# Script principal para fazer backup completo da infraestrutura

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE_DIR="./backups"  # Local backup directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_LOGS_DIR="${BACKUP_BASE_DIR}/logs"

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
BACKUP COMPLETO - POSTGRESQL + PVCs

Este script executa backup completo da infraestrutura, incluindo:
- Bases de dados PostgreSQL
- Dados dos PVCs (Persistent Volume Claims)

Uso: $0 [OPÇÕES]

OPÇÕES:
    --postgresql-only   Fazer backup apenas do PostgreSQL
    --applications-only Fazer backup apenas das Applications (n8n, grafana)
    --app APP_NAME     Fazer backup apenas de uma aplicação específica
    --skip-cleanup     Não limpar backups antigos
    --verbose          Mostrar saída detalhada dos scripts
    --help             Mostrar esta ajuda

EXEMPLOS:
    $0                          # Backup completo (PostgreSQL + todas applications)
    $0 --postgresql-only        # Apenas PostgreSQL
    $0 --applications-only      # Apenas applications (n8n, grafana)
    $0 --app n8n               # Apenas PostgreSQL + aplicação específica

CONFIGURAÇÕES:
    Diretório base: ${BACKUP_BASE_DIR}
    PostgreSQL: ${BACKUP_BASE_DIR}/postgresql/backup
    Applications: ${BACKUP_BASE_DIR}/applications/backup
    Logs: ${BACKUP_LOGS_DIR}

ESTRUTURA DO BACKUP:
./backups/
├── postgresql/
│   └── backup/
│       └── YYYYMMDD_HHMMSS/
│           ├── database1_YYYYMMDD_HHMMSS.sql.gz
│           ├── globals_YYYYMMDD_HHMMSS.sql.gz
│           └── backup_info.txt
├── pvc/
│   └── backup/
│       └── YYYYMMDD_HHMMSS/
│           ├── pvc1_data_YYYYMMDD_HHMMSS.tar.gz
│           ├── pvc1_info.json
│           └── backup_info.txt
└── logs/
    └── backup_YYYYMMDD_HHMMSS.log

EOF
}

# Verificar se diretório de logs existe
create_logs_dir() {
    if [ ! -d "${BACKUP_LOGS_DIR}" ]; then
        mkdir -p "${BACKUP_LOGS_DIR}"
        success "Diretório de logs criado: ${BACKUP_LOGS_DIR}"
    fi
}

# Verificar se scripts de backup existem
check_backup_scripts() {
    local postgresql_script="${SCRIPT_DIR}/1.backup-postgresql.sh"
    local applications_script="${SCRIPT_DIR}/2.backup-applications.sh"
    
    if [ ! -f "$postgresql_script" ]; then
        error "Script de backup PostgreSQL não encontrado: $postgresql_script"
        exit 1
    fi
    
    if [ ! -f "$applications_script" ]; then
        error "Script de backup Applications não encontrado: $applications_script"
        exit 1
    fi
    
    # Tornar scripts executáveis se necessário
    chmod +x "$postgresql_script" "$applications_script"
    
    success "Scripts de backup verificados e configurados"
}

# Executar backup PostgreSQL
run_postgresql_backup() {
    local verbose=$1
    local log_file="${BACKUP_LOGS_DIR}/postgresql_backup_${TIMESTAMP}.log"
    
    log "=== INICIANDO BACKUP POSTGRESQL ==="
    
    if [ "$verbose" = true ]; then
        if "${SCRIPT_DIR}/1.backup-postgresql.sh" 2>&1 | tee "$log_file"; then
            success "Backup PostgreSQL concluído com sucesso"
            return 0
        else
            error "Falha no backup PostgreSQL"
            return 1
        fi
    else
        if "${SCRIPT_DIR}/1.backup-postgresql.sh" > "$log_file" 2>&1; then
            success "Backup PostgreSQL concluído com sucesso"
            log "Log salvo em: $log_file"
            return 0
        else
            error "Falha no backup PostgreSQL"
            error "Verifique o log: $log_file"
            return 1
        fi
    fi
}

# Executar backup PVC
run_pvc_backup() {
    local specific_pvc=$1
    local verbose=$2
    local log_file="${BACKUP_LOGS_DIR}/pvc_backup_${TIMESTAMP}.log"
    
    log "=== INICIANDO BACKUP PVC ==="
    
    local pvc_args=""
    if [ -n "$specific_pvc" ]; then
        pvc_args="--pvc $specific_pvc"
        log "Backup específico do PVC: $specific_pvc"
    fi
    
    if [ "$verbose" = true ]; then
        if "${SCRIPT_DIR}/backup-pvc.sh" $pvc_args 2>&1 | tee "$log_file"; then
            success "Backup PVC concluído com sucesso"
            return 0
        else
            error "Falha no backup PVC"
            return 1
        fi
    else
        if "${SCRIPT_DIR}/backup-pvc.sh" $pvc_args > "$log_file" 2>&1; then
            success "Backup PVC concluído com sucesso"
            log "Log salvo em: $log_file"
            return 0
        else
            error "Falha no backup PVC"
            error "Verifique o log: $log_file"
            return 1
        fi
    fi
}

# Criar relatório de backup
create_backup_report() {
    local postgresql_success=$1
    local pvc_success=$2
    local specific_pvc=$3
    local report_file="${BACKUP_LOGS_DIR}/backup_report_${TIMESTAMP}.txt"
    
    log "Criando relatório de backup..."
    
    cat > "$report_file" << EOF
=== RELATÓRIO DE BACKUP COMPLETO ===
Data/Hora: $(date)
Timestamp: ${TIMESTAMP}

=== CONFIGURAÇÕES ===
Diretório base: ${BACKUP_BASE_DIR}
Scripts: ${SCRIPT_DIR}
Logs: ${BACKUP_LOGS_DIR}

=== RESULTADOS ===
EOF

    if [ "$postgresql_success" = true ]; then
        echo "PostgreSQL: ✅ SUCESSO" >> "$report_file"
        
        # Adicionar detalhes do backup PostgreSQL se disponível
        local pg_backup_dir="${BACKUP_BASE_DIR}/postgresql/backup/${TIMESTAMP}"
        if [ -d "$pg_backup_dir" ]; then
            echo "  Diretório: $pg_backup_dir" >> "$report_file"
            echo "  Arquivos:" >> "$report_file"
            ls -la "$pg_backup_dir" | grep -E '\.(gz|txt)$' | sed 's/^/    /' >> "$report_file"
        fi
    else
        echo "PostgreSQL: ❌ FALHA" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    
    if [ "$pvc_success" = true ]; then
        if [ -n "$specific_pvc" ]; then
            echo "PVC ($specific_pvc): ✅ SUCESSO" >> "$report_file"
        else
            echo "PVCs: ✅ SUCESSO" >> "$report_file"
        fi
        
        # Adicionar detalhes do backup PVC se disponível
        local pvc_backup_dir="${BACKUP_BASE_DIR}/pvc/backup/${TIMESTAMP}"
        if [ -d "$pvc_backup_dir" ]; then
            echo "  Diretório: $pvc_backup_dir" >> "$report_file"
            echo "  Arquivos:" >> "$report_file"
            ls -la "$pvc_backup_dir" | grep -E '\.(gz|json|txt|empty)$' | sed 's/^/    /' >> "$report_file"
        fi
    else
        if [ -n "$specific_pvc" ]; then
            echo "PVC ($specific_pvc): ❌ FALHA" >> "$report_file"
        else
            echo "PVCs: ❌ FALHA" >> "$report_file"
        fi
    fi
    
    echo "" >> "$report_file"
    echo "=== ESPAÇO EM DISCO ===" >> "$report_file"
    df -h ./backups >> "$report_file" 2>/dev/null || echo "Não foi possível verificar espaço em disco" >> "$report_file"
    
    success "Relatório criado: $report_file"
}

# Limpeza de logs antigos
cleanup_old_logs() {
    log "Limpando logs antigos (mais de 14 dias)..."
    
    find "${BACKUP_LOGS_DIR}" -name "*.log" -mtime +14 -delete 2>/dev/null || true
    find "${BACKUP_LOGS_DIR}" -name "backup_report_*.txt" -mtime +14 -delete 2>/dev/null || true
    
    success "Limpeza de logs concluída"
}

# Verificar espaço em disco
check_disk_space() {
    log "Verificando espaço em disco..."
    
    if ! df ./backups >/dev/null 2>&1; then
        warning "Não foi possível verificar espaço em disco para ./backups"
        return 0
    fi
    
    local available_gb=$(df ./backups --output=avail -BG | tail -1 | sed 's/G//')
    
    if [ "$available_gb" -lt 5 ]; then
        warning "Pouco espaço em disco disponível: ${available_gb}GB"
        warning "Recomendado pelo menos 5GB livres para backup"
    else
        success "Espaço em disco adequado: ${available_gb}GB disponíveis"
    fi
}

# Função principal
main() {
    local postgresql_only=false
    local pvc_only=false
    local specific_pvc=""
    local skip_cleanup=false
    local verbose=false
    
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
            --skip-cleanup)
                skip_cleanup=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Argumento desconhecido: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validar argumentos
    if [ "$postgresql_only" = true ] && [ "$pvc_only" = true ]; then
        error "Não é possível usar --postgresql-only e --pvc-only ao mesmo tempo"
        exit 1
    fi
    
    log "=== INICIANDO BACKUP COMPLETO ==="
    log "Timestamp: ${TIMESTAMP}"
    
    # Verificações iniciais
    create_logs_dir
    check_backup_scripts
    check_disk_space
    
    # Executar backups
    local postgresql_success=false
    local pvc_success=false
    
    if [ "$pvc_only" != true ]; then
        if run_postgresql_backup "$verbose"; then
            postgresql_success=true
        fi
    else
        postgresql_success=true  # Não executado, mas não é falha
    fi
    
    if [ "$postgresql_only" != true ]; then
        if run_pvc_backup "$specific_pvc" "$verbose"; then
            pvc_success=true
        fi
    else
        pvc_success=true  # Não executado, mas não é falha
    fi
    
    # Limpeza de logs antigos (se não foi pulado)
    if [ "$skip_cleanup" != true ]; then
        cleanup_old_logs
    fi
    
    # Criar relatório
    create_backup_report "$postgresql_success" "$pvc_success" "$specific_pvc"
    
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
        success "=== BACKUP COMPLETO CONCLUÍDO COM SUCESSO ==="
        success "Timestamp: ${TIMESTAMP}"
        
        if [ "$postgresql_only" = true ]; then
            success "Backup PostgreSQL executado com sucesso"
        elif [ "$pvc_only" = true ]; then
            if [ -n "$specific_pvc" ]; then
                success "Backup do PVC ${specific_pvc} executado com sucesso"
            else
                success "Backup de PVCs executado com sucesso"
            fi
        else
            success "Backup completo (PostgreSQL + PVCs) executado com sucesso"
        fi
        
        success "Logs disponíveis em: ${BACKUP_LOGS_DIR}"
        exit 0
    else
        warning "=== BACKUP COMPLETO CONCLUÍDO COM ${total_failures} FALHAS ==="
        warning "Verifique os logs em: ${BACKUP_LOGS_DIR}"
        exit 1
    fi
}

# Executar função principal
main "$@"