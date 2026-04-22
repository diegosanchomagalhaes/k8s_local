#!/bin/bash
set -euo pipefail
echo ">>> Reiniciando n8n..."
kubectl rollout restart deployment/n8n -n n8n
kubectl rollout status deployment/n8n -n n8n --timeout=120s
echo "n8n reiniciado."
