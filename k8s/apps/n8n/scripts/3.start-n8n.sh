#!/bin/bash
set -euo pipefail
echo ">>> Iniciando n8n..."
kubectl scale deployment n8n -n n8n --replicas=1
kubectl rollout status deployment/n8n -n n8n --timeout=120s
echo "n8n iniciado: https://n8n.local.127.0.0.1.nip.io"
