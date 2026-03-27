#!/bin/bash
set -euo pipefail

# =================================================================
# SCRIPT DE BACKUP PARA APLICAÇÕES KUBERNETES
# =================================================================
# Uso: ./backup-app.sh [app_name] [backup_type]
# 
# Tipos de backup:
#   - db: Backup apenas do banco de dados
#   - files: Backup apenas dos arquivos/volumes
#   - full: Backup completo (db + files + configs)
#
# Exemplos:
#   ./backup-app.sh n8n full
#   ./backup-app.sh n8n db
# =================================================================

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Diretórios de backup no cluster (paths dentro do k3d)
POSTGRESQL_BACKUP_DIR="/mnt/host-cluster/postgresql/backup"
PVC_BACKUP_DIR="/home/dsm/cluster/applications"

# Configurações
APP_NAME="${1:-n8n}"
BACKUP_TYPE="${2:-full}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Nomes de arquivos de backup
DB_BACKUP_FILE="$POSTGRESQL_BACKUP_DIR/${APP_NAME}_db_${TIMESTAMP}.sql.gz"
PVC_BACKUP_FILE="$PVC_BACKUP_DIR/${APP_NAME}_files_${TIMESTAMP}.tar.gz"

# Configurações por aplicação
case "$APP_NAME" in
    "n8n")
        NAMESPACE="n8n"
        DB_HOST="postgres.default.svc.cluster.local"
        DB_PORT="5432"
        DB_NAME="n8n"
        DB_USER="postgres"
        PVC_NAME="n8n-data-pvc"
        DEPLOYMENT_NAME="n8n"
        ;;
    *)
        echo "❌ Aplicação '$APP_NAME' não suportada"
        echo "📋 Aplicações disponíveis: n8n"
        exit 1
        ;;
esac

echo "🗄️ Iniciando backup da aplicação: $APP_NAME"
echo "📂 Tipo de backup: $BACKUP_TYPE"
echo "📅 Timestamp: $TIMESTAMP"
echo ""

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"

# =================================================================
# FUNÇÕES DE BACKUP
# =================================================================

backup_database() {
    echo "� [1/3] Fazendo backup do banco de dados..."
    
    # Obter senha do PostgreSQL
    DB_PASSWORD=$(kubectl get secret postgres-admin-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)
    
    # Executar backup usando pg_dump dentro do cluster
    echo "📋 Executando pg_dump para $DB_NAME..."
    kubectl exec -n default postgres-0 -- sh -c "
        export PGPASSWORD='$DB_PASSWORD'
        pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --verbose --clean --no-owner --no-privileges
    " | gzip > "$DB_BACKUP_FILE"
    
    echo "✅ Backup do banco salvo em: $DB_BACKUP_FILE"
}

backup_files() {
    echo "📁 [2/3] Fazendo backup dos arquivos/volumes..."
    
    # Criar um pod temporário para acessar o PVC
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: backup-pod-${APP_NAME}
  namespace: $NAMESPACE
spec:
  containers:
  - name: backup
    image: busybox
    command: ['sleep', '3600']
    volumeMounts:
    - name: app-data
      mountPath: /data
  volumes:
  - name: app-data
    persistentVolumeClaim:
      claimName: $PVC_NAME
  restartPolicy: Never
EOF

    # Aguardar pod ficar pronto
    echo "⏳ Aguardando pod de backup ficar pronto..."
    kubectl wait --for=condition=ready pod/backup-pod-${APP_NAME} -n $NAMESPACE --timeout=60s
    
    # Fazer backup dos arquivos diretamente para o local correto
    kubectl exec -n $NAMESPACE backup-pod-${APP_NAME} -- tar czf - -C /data . > "$PVC_BACKUP_FILE"
    
    # Remover pod temporário
    kubectl delete pod backup-pod-${APP_NAME} -n $NAMESPACE
    
    echo "✅ Backup dos arquivos salvo em: $PVC_BACKUP_FILE"
}

backup_configs() {
    echo "⚙️ [3/3] Fazendo backup das configurações Kubernetes..."
    
    # Criar diretório temporário para configs
    TEMP_CONFIG_DIR="/tmp/k8s-configs-${APP_NAME}-${TIMESTAMP}"
    mkdir -p "$TEMP_CONFIG_DIR"
    
    # Exportar recursos principais (sem secrets por segurança)
    kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o yaml > "$TEMP_CONFIG_DIR/deployment.yaml" 2>/dev/null || echo "Deployment não encontrado"
    kubectl get service -n $NAMESPACE -o yaml > "$TEMP_CONFIG_DIR/services.yaml" 2>/dev/null || echo "Services não encontrados"
    kubectl get ingress -n $NAMESPACE -o yaml > "$TEMP_CONFIG_DIR/ingress.yaml" 2>/dev/null || echo "Ingress não encontrado"
    kubectl get pvc -n $NAMESPACE -o yaml > "$TEMP_CONFIG_DIR/pvc.yaml" 2>/dev/null || echo "PVC não encontrado"
    kubectl get hpa -n $NAMESPACE -o yaml > "$TEMP_CONFIG_DIR/hpa.yaml" 2>/dev/null || echo "HPA não encontrado"
    kubectl get certificate -n $NAMESPACE -o yaml > "$TEMP_CONFIG_DIR/certificates.yaml" 2>/dev/null || echo "Certificates não encontrados"
    
    # Comprimir configs e salvar no diretório de backup do PVC
    CONFIG_BACKUP_FILE="$PVC_BACKUP_DIR/${APP_NAME}_configs_${TIMESTAMP}.tar.gz"
    tar czf "$CONFIG_BACKUP_FILE" -C "/tmp" "$(basename "$TEMP_CONFIG_DIR")"
    
    # Limpar diretório temporário
    rm -rf "$TEMP_CONFIG_DIR"
    
    echo "✅ Backup das configurações salvo em: $CONFIG_BACKUP_FILE"
}

# =================================================================
# EXECUÇÃO DO BACKUP
# =================================================================

case "$BACKUP_TYPE" in
    "db")
        backup_database
        ;;
    "files")
        backup_files
        ;;
    "full")
        backup_database
        backup_files
        backup_configs
        ;;
    *)
        echo "❌ Tipo de backup '$BACKUP_TYPE' inválido"
        echo "📋 Tipos disponíveis: db, files, full"
        exit 1
        ;;
esac

# =================================================================
# FINALIZAÇÃO
# =================================================================

# Calcular tamanho do backup
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# Criar arquivo de metadados
cat > "$BACKUP_DIR/backup_info.json" <<EOF
{
    "app_name": "$APP_NAME",
    "backup_type": "$BACKUP_TYPE",
    "timestamp": "$TIMESTAMP",
    "date": "$(date -Iseconds)",
    "kubernetes_version": "$(kubectl version --short --client | grep Client)",
    "backup_size": "$BACKUP_SIZE",
    "files": $(ls -1 "$BACKUP_DIR"/*.gz 2>/dev/null | wc -l)
}
EOF

echo ""
echo "🎉 Backup concluído com sucesso!"
echo "📂 Local: $BACKUP_DIR"
echo "💾 Tamanho: $BACKUP_SIZE"
echo "📋 Arquivos criados:"
ls -la "$BACKUP_DIR"

echo ""
echo "🔄 Para restaurar, use: ./restore-app.sh $APP_NAME $TIMESTAMP"