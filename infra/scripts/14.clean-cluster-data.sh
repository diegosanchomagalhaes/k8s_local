#!/bin/bash

###############################################################################
# Script: 14.clean-cluster-data.sh
# Descrição: Remove databases do PostgreSQL e MariaDB
#            ⚠️ REQUER CLUSTER RODANDO
# Autor: DevOps Team
# Data: 2025-01-06
###############################################################################

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   LIMPEZA DE DATABASES - POSTGRESQL E MARIADB            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá:${NC}"
echo -e "${YELLOW}   - Dropar databases: n8n, grafana, prometheus, zabbix (PostgreSQL)${NC}"
echo -e "${YELLOW}   - Dropar databases: glpi, zabbix_proxy (MariaDB)${NC}"
echo ""
echo -e "${RED}⚠️  TODOS OS DADOS DOS BANCOS SERÃO PERDIDOS!${NC}"
echo ""

# Confirmação
read -p "Deseja continuar? (SIM/não): " confirmacao
if [[ "$confirmacao" != "SIM" ]]; then
    echo -e "${YELLOW}❌ Operação cancelada pelo usuário${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔍 Verificando se o cluster está rodando...${NC}"

# Verificar se o cluster está rodando
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${YELLOW}⚠️  Cluster não está rodando - pulando drop de databases${NC}"
    echo -e "${BLUE}💡 Databases não serão dropados (cluster já foi destruído)${NC}"
    echo ""
    echo -e "${GREEN}✅ Limpeza de databases concluída (nada a fazer)${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Cluster detectado e rodando${NC}"

###############################################################################
# DROP DE DATABASES
###############################################################################

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DROPANDO BANCOS DE DADOS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# PostgreSQL - Drop databases
echo ""
echo -e "${YELLOW}📦 Dropando databases do PostgreSQL...${NC}"

# Verificar se o PostgreSQL está rodando
if kubectl get pod -n postgres postgres-0 &>/dev/null; then
    echo -e "${BLUE}  → Dropando database 'n8n'...${NC}"
    kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS n8n;" 2>/dev/null || echo -e "${YELLOW}    ⚠️  Database 'n8n' não existe ou já foi removido${NC}"
    
    echo -e "${BLUE}  → Dropando database 'grafana'...${NC}"
    kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS grafana;" 2>/dev/null || echo -e "${YELLOW}    ⚠️  Database 'grafana' não existe ou já foi removido${NC}"
    
    echo -e "${BLUE}  → Dropando database 'prometheus'...${NC}"
    kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS prometheus;" 2>/dev/null || echo -e "${YELLOW}    ⚠️  Database 'prometheus' não existe ou já foi removido${NC}"
    
    echo -e "${BLUE}  → Dropando database 'zabbix'...${NC}"
    kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS zabbix;" 2>/dev/null || echo -e "${YELLOW}    ⚠️  Database 'zabbix' não existe ou já foi removido${NC}"
    
    echo -e "${GREEN}✅ Databases PostgreSQL removidos${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL não está rodando. Pulando...${NC}"
fi

# MariaDB - Drop database
echo ""
echo -e "${YELLOW}📦 Dropando database do MariaDB...${NC}"

# Obter senha do MariaDB
MARIADB_PASSWORD=$(kubectl get secret -n mariadb mariadb-admin-secret -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' 2>/dev/null | base64 -d || echo "")

if [ -n "$MARIADB_PASSWORD" ] && kubectl get pod -n mariadb mariadb-0 &>/dev/null; then
    echo -e "${BLUE}  → Dropando database 'glpi'...${NC}"
    kubectl exec -n mariadb mariadb-0 -- mariadb -uroot -p"$MARIADB_PASSWORD" -e "DROP DATABASE IF EXISTS glpi;" 2>/dev/null || echo -e "${YELLOW}    ⚠️  Database 'glpi' não existe ou já foi removido${NC}"
    
    echo -e "${BLUE}  → Dropando database 'zabbix_proxy'...${NC}"
    kubectl exec -n mariadb mariadb-0 -- mariadb -uroot -p"$MARIADB_PASSWORD" -e "DROP DATABASE IF EXISTS zabbix_proxy;" 2>/dev/null || echo -e "${YELLOW}    ⚠️  Database 'zabbix_proxy' não existe ou já foi removido${NC}"
    
    echo -e "${GREEN}✅ Databases MariaDB removidos${NC}"
else
    echo -e "${YELLOW}⚠️  MariaDB não está rodando ou secret não encontrado. Pulando...${NC}"
fi

###############################################################################
# FINALIZAÇÃO
###############################################################################

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DATABASES REMOVIDOS COM SUCESSO!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "${BLUE}   1. Execute: ./infra/scripts/2.destroy-infra.sh${NC}"
echo -e "${BLUE}   2. Execute: ./infra/scripts/15.clean-cluster-pvc.sh${NC}"
echo -e "${BLUE}   3. Execute: ./start-all.sh${NC}"
echo -e "${BLUE}   OU execute tudo de uma vez: ./infra/scripts/18.destroy-all.sh${NC}"
echo ""
