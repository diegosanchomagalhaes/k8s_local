#!/bin/bash
set -euo pipefail

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/4] Criando cluster k3d ========"
k3d cluster create --config infra/k3d/k3d-config.yaml

echo "======== [2/4] Criando StorageClass hostpath-storage ========"
kubectl apply -f infra/storage/hostpath-storageclass.yaml

echo "======== [3/4] Instalando cert-manager ========"
# Instalar cert-manager via kubectl (método oficial)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.0/cert-manager.yaml

echo "[INFO] Aguardando pods do cert-manager ficarem prontos..."
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager-cainjector -n cert-manager  
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager-webhook -n cert-manager

# ClusterIssuer self-signed (para TLS local)
echo "[INFO] Aplicando ClusterIssuer self-signed..."
kubectl apply -f infra/cert-manager/cluster-issuer-selfsigned.yaml

echo "======== [4/5] Subindo PostgreSQL ========"
kubectl apply -f infra/postgres/postgres-pv-hostpath.yaml
kubectl apply -f infra/postgres/postgres-pvc.yaml
kubectl apply -f infra/postgres/postgres-secret-admin.yaml
kubectl apply -f infra/postgres/postgres.yaml

echo "[INFO] Aguardando PostgreSQL ficar pronto..."
kubectl rollout status statefulset/postgres -n postgres

echo "======== [5/5] Subindo MariaDB ========"
kubectl apply -f infra/mariadb/mariadb-pv-hostpath.yaml
kubectl apply -f infra/mariadb/mariadb-pvc.yaml
kubectl apply -f infra/mariadb/mariadb-secret-admin.yaml
kubectl apply -f infra/mariadb/mariadb-deployment.yaml

echo "[INFO] Aguardando MariaDB ficar pronto..."
kubectl rollout status statefulset/mariadb -n mariadb

echo "======== Infraestrutura pronta ========"
echo "Cluster: k3d-cluster"
echo "StorageClass: hostpath-storage"
echo "Ingress Controller: Traefik (padrão do k3d/k3s)"
echo "Cert-manager: namespace cert-manager"
echo "PostgreSQL: namespace postgres"
echo "MariaDB: namespace mariadb"
echo "Host interno para apps PostgreSQL: postgres.postgres.svc.cluster.local:5432"
echo "Host interno para apps MariaDB: mariadb.mariadb.svc.cluster.local:3306"