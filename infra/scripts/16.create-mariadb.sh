#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Criando MariaDB na infra ========"

echo "[1/4] Criando namespace mariadb..."
kubectl apply -f infra/mariadb/mariadb-deployment.yaml

echo "[2/4] Aplicando PV hostPath..."
kubectl apply -f infra/mariadb/mariadb-pv-hostpath.yaml

echo "[2.5/4] Aplicando PVC..."
kubectl apply -f infra/mariadb/mariadb-pvc.yaml

echo "[3/4] Criando Secret admin..."
kubectl apply -f infra/mariadb/mariadb-secret-admin.yaml

echo "[4/4] Aguardando MariaDB ficar pronto..."
kubectl rollout status statefulset/mariadb -n mariadb

echo "======== MariaDB pronto no namespace mariadb ========"
echo "Host interno: mariadb.mariadb.svc.cluster.local:3306"