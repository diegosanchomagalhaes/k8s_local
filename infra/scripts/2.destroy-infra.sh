#!/bin/bash
set -euo pipefail
# ==============================================================================
#  PASB — Destruição Completa da Infraestrutura
#  ATENÇÃO: Remove cluster e todos os dados!
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================"
echo "  PASB — DESTRUIÇÃO DA INFRAESTRUTURA"
echo "  ATENÇÃO: Esta operação é IRREVERSÍVEL!"
echo "================================================================"
read -rp "Confirma? (yes/N): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && echo "Abortado." && exit 0

echo ""
echo ">>> Removendo cluster k3d pasb-cluster..."
bash "${SCRIPT_DIR}/4.delete-cluster.sh"

echo ""
echo "================================================================"
echo "  Cluster removido. Dados em /home/dsm/cluster-pasb preservados."
echo "  Para remover os dados: rm -rf /home/dsm/cluster-pasb"
echo "================================================================"
