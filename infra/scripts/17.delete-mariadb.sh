#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo MariaDB da infra ========"

echo "[1/4] Removendo StatefulSet..."
kubectl delete statefulset mariadb -n mariadb --ignore-not-found=true

echo "[2/4] Removendo Service..."
kubectl delete service mariadb -n mariadb --ignore-not-found=true

echo "[3/4] Removendo Secret..."
kubectl delete secret mariadb-admin-secret -n mariadb --ignore-not-found=true

echo "[4/4] Removendo namespace..."
kubectl delete namespace mariadb --ignore-not-found=true

echo "[INFO] PV e PVC não removidos (dados preservados)"
echo "Para remover completamente, execute:"
echo "  kubectl delete pv mariadb-pv-hostpath"
echo "  kubectl delete pvc mariadb-pvc -n mariadb"

echo "======== MariaDB removido ========"