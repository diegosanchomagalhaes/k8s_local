#!/bin/bash
set -euo pipefail

echo "📂 Criando nova estrutura de diretórios organizada..."

# Diretório base do cluster (hostPath para persistência)
CLUSTER_BASE="/home/dsm/cluster"
echo "📁 Base de dados: $CLUSTER_BASE"

# Criar estrutura de diretórios (PostgreSQL + PVC hostPath, Redis local-path)
echo "🗂️ Criando diretórios base..."
sudo mkdir -p "$CLUSTER_BASE/postgresql"
sudo mkdir -p "$CLUSTER_BASE/postgresql/backup"
sudo mkdir -p "$CLUSTER_BASE/pvc"
sudo mkdir -p "$CLUSTER_BASE/pvc/backup"

echo "🏗️ Criando subdiretórios para aplicações..."

# Diretórios específicos do PostgreSQL
sudo mkdir -p "$CLUSTER_BASE/postgresql/data"
sudo mkdir -p "$CLUSTER_BASE/postgresql/backup/full"
sudo mkdir -p "$CLUSTER_BASE/postgresql/backup/n8n"
sudo mkdir -p "$CLUSTER_BASE/postgresql/backup/grafana"

# Diretórios das aplicações dentro de applications/ (organizado)
sudo mkdir -p "$CLUSTER_BASE/applications/n8n/config"
sudo mkdir -p "$CLUSTER_BASE/applications/n8n/files"
sudo mkdir -p "$CLUSTER_BASE/applications/grafana/data"
sudo mkdir -p "$CLUSTER_BASE/applications/grafana/logs"

# Diretório do Redis (seguindo o mesmo padrão do PostgreSQL)
sudo mkdir -p "$CLUSTER_BASE/redis"

# Definir permissões adequadas (igual ao PostgreSQL que funciona)
echo "🔐 Configurando permissões..."
sudo chmod -R 777 "$CLUSTER_BASE"

# Definir permissões específicas para cada aplicação
echo "🔧 Ajustando permissões específicas das aplicações..."
# PostgreSQL (UID 999) - mantém como está
sudo chown -R 999:999 "$CLUSTER_BASE/postgresql/data"
# Applications - usar permissões abertas (777) para evitar problemas de UID
sudo chmod -R 777 "$CLUSTER_BASE/applications"
# Manter dono como dsm para poder apagar facilmente
sudo chown -R dsm:dsm "$CLUSTER_BASE/applications"
# Redis - usar permissões adequadas (proprietário dsm:dsm)
sudo chown -R dsm:dsm "$CLUSTER_BASE/redis"

# Verificar estrutura criada
echo "✅ Estrutura criada com sucesso!"
echo ""
echo "📋 Nova estrutura de diretórios:"
tree "$CLUSTER_BASE" 2>/dev/null || find "$CLUSTER_BASE" -type d | sort

echo ""
echo "🎯 Próximos passos:"
echo "1. Execute o destroy da infraestrutura atual"
echo "2. Suba novamente com: ./infra/scripts/9.start-infra.sh"
echo "3. Deploy do n8n com: ./k8s/apps/n8n/scripts/1.deploy-n8n.sh"

echo ""
echo "💡 Os novos locais serão:"
echo "   - PostgreSQL data: $CLUSTER_BASE/postgresql/data"
echo "   - PostgreSQL backups: $CLUSTER_BASE/postgresql/backup/"
echo "   - Redis data: $CLUSTER_BASE/redis (hostPath persistente)"
echo "   - n8n config: $CLUSTER_BASE/applications/n8n/config"
echo "   - n8n files: $CLUSTER_BASE/applications/n8n/files"
echo "   - Grafana data: $CLUSTER_BASE/applications/grafana/data"
echo "   - Grafana logs: $CLUSTER_BASE/applications/grafana/logs"
echo ""
echo "⚠️  IMPORTANTE: Para usar hostPath persistente:"
echo "   1. Configure o path em cada arquivo *-pv-hostpath.yaml.template"
echo "   2. Substitua [CLUSTER_BASE_PATH] por: $CLUSTER_BASE"
echo "   3. Use os scripts de deploy que aplicam os PVs hostPath"
echo ""
echo "📋 Estratégia de persistência:"
echo "   ✅ PostgreSQL: hostPath persistente (sobrevive ao destroy do cluster)"
echo "   ✅ n8n: hostPath persistente (sobrevive ao destroy do cluster)"
echo "   ✅ Grafana: hostPath persistente (sobrevive ao destroy do cluster)"
echo "   ⚠️  Redis: local-path (cache - pode ser recriado)"