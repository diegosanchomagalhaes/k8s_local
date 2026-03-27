# WSL2 - Configuração Otimizada para K3D Local

> Configuração recomendada do WSL2 para ambiente de desenvolvimento com k3d, PostgreSQL e n8n.

## 📋 Sumário

- [Visão Geral](#-visão-geral)
- [Configuração Recomendada](#-configuração-recomendada)
- [Arquivo .wslconfig](#-arquivo-wslconfig)
- [Sugestões por Recurso de Hardware](#-sugestões-por-recurso-de-hardware)
- [Comandos Úteis](#-comandos-úteis)
- [Solução de Problemas](#-solução-de-problemas)

## 🎯 Visão Geral

O WSL2 precisa ser configurado adequadamente para rodar:

- **k3d cluster** (1 server + 2 agents)
- **PostgreSQL 16** com databases (n8n, grafana, prometheus)
- **MariaDB 12.2.2** com database (glpi)
- **Redis 8.6.2** cache compartilhado (DB0-DB3)
- **n8n 1.118.2** com processamento de workflows
- **Grafana 12.4.2** dashboards e monitoramento
- **Prometheus v3.10.0** métricas e alertas
- **GLPI 11.0.6** service desk e inventário
- **cert-manager** e **Traefik**

## ⚙️ Configuração Recomendada

### 📁 **Localização do Arquivo**

**No Windows, crie/edite o arquivo:**

```
C:\Users\SEU_USUARIO\.wslconfig
```

**Onde `SEU_USUARIO` é seu nome de usuário do Windows.**

### 🛠️ **Como Criar/Editar:**

1. **Pelo Explorador de Arquivos:**

   - Abra: `C:\Users\[SEU_USUARIO]\`
   - Crie arquivo: `.wslconfig` (com o ponto no início)

2. **Pelo PowerShell/CMD:**

   ```cmd
   notepad %USERPROFILE%\.wslconfig
   ```

3. **Pelo Terminal do Windows:**
   ```powershell
   code $env:USERPROFILE\.wslconfig
   ```

### 💾 **Configuração Base (.wslconfig)**

```ini
# Settings apply across all Linux distros running on WSL 2
[wsl2]

# Memória RAM - 50-60% da RAM total disponível
memory=8GB

# CPU - 50-75% dos cores disponíveis
processors=2

# Swap - Igual à RAM alocada para WSL2
swap=8GB

# Local do swap (SSD recomendado para performance)
swapfile=E:\wsl\prod\swap\swap.vhdx

# Otimizações para containers
pageReporting=false
localhostforwarding=true
nestedVirtualization=false

# Debug habilitado para troubleshooting
debugConsole=true

# Recursos experimentais para otimização
[experimental]
sparseVhd=true
autoMemoryReclaim=gradual
```

## 🔧 Sugestões por Recurso de Hardware

### **💻 Sistema com 8GB RAM**

```ini
memory=4GB          # 50% da RAM total
processors=2        # 50% dos cores (se tiver 4+ cores)
swap=4GB           # Igual à RAM alocada
```

### **💻 Sistema com 16GB RAM**

```ini
memory=8GB          # 50% da RAM total
processors=4        # 50-75% dos cores
swap=8GB           # Igual à RAM alocada
```

### **💻 Sistema com 32GB RAM**

```ini
memory=12GB         # 37.5% da RAM total
processors=6        # 50-75% dos cores
swap=8GB           # Menor que RAM (otimização)
```

### **🖥️ Workstation (64GB+ RAM)**

```ini
memory=16GB         # 25% da RAM total
processors=8        # 50-75% dos cores
swap=8GB           # Swap menor (performance)
```

## 📝 Arquivo .wslconfig Completo

```ini
# ==================================================================
# WSL2 - Configuração K3D Local
# Otimizada para k3d + PostgreSQL + MariaDB + Redis + 4 aplicações
# (n8n, Grafana, Prometheus, GLPI)
# ==================================================================

[wsl2]
# Memória: 50-60% da RAM total (ajuste conforme seu hardware)
# Recomendado: mínimo 8GB para rodar todas as 4 aplicações
memory=8GB

# CPU: 50-75% dos cores disponíveis
processors=2

# Swap: Igual à RAM alocada (máximo 8GB recomendado)
swap=8GB

# Local do swap em SSD para melhor performance
swapfile=E:\wsl\prod\swap\swap.vhdx

# Otimizações para containers e networking
pageReporting=false
localhostforwarding=true
nestedVirtualization=false

# Debug para troubleshooting
debugConsole=true

# ==================================================================
# Recursos Experimentais - Otimização de Disco e Memória
# ==================================================================
[experimental]
# Compactação automática do disco virtual
sparseVhd=true

# Liberação automática de memória RAM
autoMemoryReclaim=gradual
```

## 🚀 Comandos Úteis

### **Aplicar Nova Configuração**

### **📝 Como Aplicar as Configurações**

1. **Editar o arquivo `.wslconfig`** (veja caminhos acima)
2. **Salvar o arquivo**
3. **Reiniciar o WSL2:**
   ```powershell
   # No PowerShell/CMD do Windows
   wsl --shutdown
   wsl
   ```

### **✅ Verificar se Aplicou Corretamente**

```bash
# No terminal WSL2, verificar recursos
free -h          # Memória disponível
nproc           # CPU cores disponíveis
df -h           # Espaço em disco
```

### **🔄 Comandos de Gerenciamento WSL2**

```powershell
# No Windows PowerShell/CMD:
wsl --shutdown                    # Desligar WSL2
wsl --status                      # Ver status
wsl --list --verbose              # Listar distribuições
wsl --unregister Ubuntu           # Remover distro (cuidado!)
```

### **Monitoramento de Recursos**

```bash
# Monitoring em tempo real
htop

# Uso de memória detalhado
cat /proc/meminfo

# Processos que mais consomem recursos
ps aux --sort=-%mem | head -10
```

## 🐛 Solução de Problemas

### **❌ "Memória Insuficiente" durante deploy**

```ini
# Aumentar memória e swap
memory=12GB
swap=12GB
```

### **❌ "Too many open files" no k3d**

```bash
# Adicionar ao ~/.bashrc do WSL2
echo 'ulimit -n 65536' >> ~/.bashrc
source ~/.bashrc
```

### **❌ Performance lenta do PostgreSQL**

```ini
# Mover swap para SSD mais rápido
swapfile=C:\wsl\swap\swap.vhdx

# Desabilitar page reporting
pageReporting=false
```

### **❌ Containers não conseguem se comunicar**

```ini
# Habilitar localhost forwarding
localhostforwarding=true

# Verificar se ports estão mapeados no k3d
# Veja k3d-config.yaml
```

## 📊 Monitoramento de Performance

### **Durante o desenvolvimento:**

```bash
# Ver uso de recursos do k3d
kubectl top nodes
kubectl top pods --all-namespaces

# Monitorar Docker
docker stats

# Ver processos WSL2 no Windows
tasklist | findstr wsl
```

### **Sinais de que precisa mais recursos:**

- ❌ Pods ficam em `Pending` por muito tempo
- ❌ `kubectl` commands muito lentos
- ❌ PostgreSQL com queries lentas
- ❌ n8n workflows falhando por timeout

## 🔄 Backup da Configuração

```bash
# Backup do .wslconfig
copy C:\Users\%USERNAME%\.wslconfig C:\backup\.wslconfig.bak

# Restaurar configuração
copy C:\backup\.wslconfig.bak C:\Users\%USERNAME%\.wslconfig
wsl --shutdown
```

## 📚 Recursos Adicionais

- [WSL2 Official Docs](https://docs.microsoft.com/en-us/windows/wsl/)
- [k3d System Requirements](https://k3d.io/v5.8.0/usage/advanced/podman/)
- [Docker WSL2 Backend](https://docs.docker.com/desktop/wsl/)

---

> **💡 Dica**: Depois de alterar `.wslconfig`, sempre execute `wsl --shutdown` para aplicar as mudanças.

> **⚠️ Importante**: Monitore o uso de recursos nos primeiros dias para ajustar os valores conforme necessário.
