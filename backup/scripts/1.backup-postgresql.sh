#!/bin/bash

# Backup PostgreSQL Databases
# Cria backup das bases de dados PostgreSQL usando kubectl

set -euo pipefail

# Configurações
NAMESPACE="postgres"
POSTGRES_POD="postgres-0"
BACKUP_BASE_DIR="./backups/postgresql"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKUP_BASE_DIR}/${TIMESTAMP}"

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

# Criar diretório de backup
create_backup_dir() {
    log "Criando diretório de backup: ${BACKUP_DIR}"
    
    if ! mkdir -p "${BACKUP_DIR}"; then
        error "Falha ao criar diretório de backup: ${BACKUP_DIR}"
        exit 1
    fi
    
    success "Diretório de backup criado"
}

# Obter lista de databases
get_databases() {
    log "Obtendo lista de databases..."
    
    local databases=$(kubectl exec -it ${POSTGRES_POD} -n ${NAMESPACE} -- \
        psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';" | \
        tr -d '\r' | sed '/^$/d' | xargs)
    
    if [ -z "$databases" ]; then
        warning "Nenhuma database de usuário encontrada, fazendo backup apenas do schema public"
        echo "n8n"  # Assumindo que temos pelo menos a database n8n
    else
        echo "$databases"
    fi
}

# Fazer backup de uma database específica
backup_database() {
    local db_name=$1
    local backup_file="${BACKUP_DIR}/${db_name}_${TIMESTAMP}.sql"
    
    log "Fazendo backup da database: ${db_name}"
    
    # Backup usando pg_dump
    if kubectl exec ${POSTGRES_POD} -n ${NAMESPACE} -- \
        pg_dump -U postgres -d ${db_name} --clean --if-exists > "${backup_file}"; then
        
        # Verificar se o arquivo foi criado e não está vazio
        if [ -s "${backup_file}" ]; then
            success "Backup da database ${db_name} criado: $(basename ${backup_file})"
            
            # Compactar o arquivo
            gzip "${backup_file}"
            success "Backup compactado: $(basename ${backup_file}).gz"
        else
            error "Arquivo de backup vazio para ${db_name}"
            rm -f "${backup_file}"
            return 1
        fi
    else
        error "Falha no backup da database ${db_name}"
        return 1
    fi
}

# Fazer backup global (roles, tablespaces, etc.)
backup_globals() {
    local backup_file="${BACKUP_DIR}/globals_${TIMESTAMP}.sql"
    
    log "Fazendo backup dos objetos globais (roles, tablespaces, etc.)..."
    
    if kubectl exec ${POSTGRES_POD} -n ${NAMESPACE} -- \
        pg_dumpall -U postgres --globals-only > "${backup_file}"; then
        
        if [ -s "${backup_file}" ]; then
            success "Backup dos objetos globais criado: $(basename ${backup_file})"
            gzip "${backup_file}"
            success "Backup compactado: $(basename ${backup_file}).gz"
        else
            warning "Arquivo de backup global vazio"
            rm -f "${backup_file}"
        fi
    else
        error "Falha no backup dos objetos globais"
    fi
}

# Criar arquivo de informações do backup
create_backup_info() {
    local info_file="${BACKUP_DIR}/backup_info.txt"
    
    log "Criando arquivo de informações do backup..."
    
    cat > "${info_file}" << EOF
=== INFORMAÇÕES DO BACKUP POSTGRESQL ===
Data/Hora: $(date)
Timestamp: ${TIMESTAMP}
Namespace: ${NAMESPACE}
Pod PostgreSQL: ${POSTGRES_POD}
Diretório: ${BACKUP_DIR}

=== VERSÃO DO POSTGRESQL ===
$(kubectl exec ${POSTGRES_POD} -n ${NAMESPACE} -- psql -U postgres -t -c "SELECT version();")

=== DATABASES INCLUÍDAS ===
EOF

    # Adicionar lista de databases
    for db in $(get_databases); do
        echo "- ${db}" >> "${info_file}"
    done
    
    echo "" >> "${info_file}"
    echo "=== ARQUIVOS DE BACKUP ===" >> "${info_file}"
    ls -la "${BACKUP_DIR}"/*.gz >> "${info_file}" 2>/dev/null || true
    
    success "Arquivo de informações criado: $(basename ${info_file})"
}

# Limpeza de backups antigos (manter apenas os últimos 7 dias)
cleanup_old_backups() {
    log "Limpando backups antigos (mais de 7 dias)..."
    
    find "${BACKUP_BASE_DIR}" -type d -name "20*" -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
    
    success "Limpeza de backups antigos concluída"
}

# Função principal
main() {
    log "=== INICIANDO BACKUP POSTGRESQL ==="
    
    check_kubectl
    check_postgres_pod
    create_backup_dir
    
    # Backup dos objetos globais
    backup_globals
    
    # Backup de cada database
    local databases=$(get_databases)
    local failed_backups=0
    
    for db in $databases; do
        if ! backup_database "$db"; then
            ((failed_backups++))
        fi
    done
    
    # Criar arquivo de informações
    create_backup_info
    
    # Limpeza de backups antigos
    cleanup_old_backups
    
    if [ $failed_backups -eq 0 ]; then
        success "=== BACKUP POSTGRESQL CONCLUÍDO COM SUCESSO ==="
        success "Diretório de backup: ${BACKUP_DIR}"
        success "Arquivos criados:"
        ls -la "${BACKUP_DIR}"
    else
        warning "=== BACKUP POSTGRESQL CONCLUÍDO COM ${failed_backups} FALHAS ==="
        warning "Verifique os logs acima para detalhes"
        exit 1
    fi
}

# Verificar argumentos
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Uso: $0 [opções]"
    echo ""
    echo "Este script cria backup das databases PostgreSQL."
    echo ""
    echo "Configurações:"
    echo "  Namespace: ${NAMESPACE}"
    echo "  Pod PostgreSQL: ${POSTGRES_POD}"
    echo "  Diretório de backup: ${BACKUP_BASE_DIR}"
    echo ""
    echo "O backup inclui:"
    echo "  - Todas as databases de usuário"
    echo "  - Objetos globais (roles, tablespaces, etc.)"
    echo "  - Arquivo de informações do backup"
    echo ""
    echo "Os arquivos são compactados automaticamente com gzip."
    echo "Backups antigos (mais de 7 dias) são removidos automaticamente."
    exit 0
fi

# Executar função principal
main