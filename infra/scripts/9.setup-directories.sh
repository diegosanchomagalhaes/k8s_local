#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Setup de Diretórios do Host
#  Cria a estrutura de diretórios persistentes em /home/dsm/cluster-pasb
# ==============================================================================
CLUSTER_BASE_PATH="${CLUSTER_BASE_PATH:-/home/dsm/cluster-pasb}"

echo "[PASB] Criando estrutura de diretórios em: $CLUSTER_BASE_PATH"

directories=(
  "$CLUSTER_BASE_PATH/postgresql/data"
  "$CLUSTER_BASE_PATH/redis"
  "$CLUSTER_BASE_PATH/minio/data"
  "$CLUSTER_BASE_PATH/kafka/data"
  "$CLUSTER_BASE_PATH/applications/n8n"
  "$CLUSTER_BASE_PATH/applications/grafana"
  "$CLUSTER_BASE_PATH/applications/zabbix/frontend"
  "$CLUSTER_BASE_PATH/applications/zabbix/data"
  "$CLUSTER_BASE_PATH/applications/glpi"
  "$CLUSTER_BASE_PATH/applications/identity-service"
)

for dir in "${directories[@]}"; do
  mkdir -p "$dir"
  echo "  [OK] $dir"
done

echo "[PASB] Diretórios criados com sucesso."
