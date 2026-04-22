#!/bin/bash
set -euo pipefail
echo ">>> Removendo n8n do cluster..."
kubectl delete namespace n8n --ignore-not-found
kubectl delete pv n8n-pv-hostpath n8n-data-pv-hostpath --ignore-not-found
echo "n8n removido. Dados em cluster-pasb/applications/n8n preservados."
