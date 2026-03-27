#!/bin/bash
set -euo pipefail

read -p "Tem certeza que deseja deletar o cluster k3d-cluster? (y/N) " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
  k3d cluster delete k3d-cluster
else
  echo "Operação cancelada."
fi