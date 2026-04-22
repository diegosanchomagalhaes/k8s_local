#!/bin/bash
set -euo pipefail
CLUSTER_BASE_PATH="${CLUSTER_BASE_PATH:-/home/dsm/cluster-pasb}"
read -rp "Confirma remoção dos volumes n8n em $CLUSTER_BASE_PATH/applications/n8n? (yes/N): " C
[[ "$C" != "yes" ]] && echo "Abortado." && exit 0
rm -rf "$CLUSTER_BASE_PATH/applications/n8n" "$CLUSTER_BASE_PATH/applications/n8n-files"
echo "Volumes n8n removidos."
