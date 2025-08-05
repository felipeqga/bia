# Guia de Implementação FastMCP - Projeto BIA

## 🎯 **Visão Geral**

Este guia documenta a implementação completa do FastMCP no projeto BIA, incluindo automação, integração com Amazon Q e coexistência com o sistema MCP tradicional.

## 📋 **Pré-requisitos**

- Sistema MCP tradicional funcionando
- Python 3.11+ instalado
- FastMCP instalado (`pip install fastmcp`)
- Amazon Q configurado com mcp.json

## 🏗️ **Arquitetura Implementada**

### **Estrutura de Arquivos**
```
/home/ec2-user/bia/
├── fastmcp-server/
│   └── bia_fastmcp_server.py          # Servidor FastMCP customizado
├── scripts/
│   ├── start-fastmcp.sh               # Script de inicialização
│   └── autostart-fastmcp.sh           # Auto-start no login
├── qbia                               # Comando principal automatizado
└── .amazonq/
    ├── mcp.json                       # Configuração expandida (4 servers)
    └── mcp.json.backup                # Backup do original
```

### **Fluxo de Automação**
```
Login SSH → ~/.bashrc → autostart-fastmcp.sh → FastMCP em background
     ↓
Comando qbia → start-fastmcp.sh → Verifica/Inicia FastMCP → Amazon Q
     ↓
Amazon Q carrega 4 MCP servers → Comandos customizados disponíveis
```

## 🔧 **Componentes Implementados**

### **1. Servidor FastMCP Customizado**

**Localização:** `/home/ec2-user/bia/fastmcp-server/bia_fastmcp_server.py`

**Comandos Disponíveis:**
- `list_ec2_instances()` - Lista instâncias EC2 da conta
- `create_security_group(name, description)` - Cria Security Groups
- `check_ecs_cluster_status()` - Status do cluster ECS BIA
- `bia_project_info()` - Informações do projeto BIA

**Recursos:**
- `bia://status` - Status do sistema FastMCP

### **2. Script de Inicialização**

**Localização:** `/home/ec2-user/bia/scripts/start-fastmcp.sh`

**Funcionalidades:**
- Verificação se FastMCP já está rodando
- Controle de PID em `/tmp/bia-fastmcp.pid`
- Verificação de porta disponível
- Execução em background via `nohup`
- Logs em `/tmp/bia-fastmcp.log`

**Uso:**
```bash
/home/ec2-user/bia/scripts/start-fastmcp.sh
```

### **3. Comando QBIA Automatizado**

**Localização:** `/home/ec2-user/bia/qbia`

**Funcionalidades:**
- Inicia FastMCP automaticamente se necessário
- Carrega contexto completo do projeto (48 arquivos .md)
- Executa Amazon Q com 4 MCP servers
- Interface amigável com status visual

**Uso:**
```bash
qbia
```

### **4. Auto-start no Login**

**Localização:** `/home/ec2-user/bia/scripts/autostart-fastmcp.sh`

**Integração:** Adicionado ao `~/.bashrc`

**Funcionalidades:**
- Inicia FastMCP automaticamente no login SSH
- Cria alias global para `qbia`
- Adiciona diretório BIA ao PATH

## ⚙️ **Configuração MCP Expandida**

### **mcp.json Atualizado**
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/ec2-user/bia"],
      "env": {
        "ALLOWED_DIRECTORIES": "/home/ec2-user/bia"
      }
    },
    "awslabs.ecs-mcp-server": {
      "command": "uvx",
      "args": ["--from", "awslabs-ecs-mcp-server", "ecs-mcp-server"],
      "env": {        
        "FASTMCP_LOG_LEVEL": "ERROR",
        "FASTMCP_LOG_FILE": "/tmp/ecs-mcp-server.log",
        "ALLOW_WRITE": "false",
        "ALLOW_SENSITIVE_DATA": "false"
      }
    },
    "postgres": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "mcp/postgres",
        "postgresql://postgres:Kgegwlaj6mAIxzHaEqgo@bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432/bia"
      ]
    },
    "bia-fastmcp": {
      "command": "python3",
      "args": ["-c", "from fastmcp import Client; import asyncio; client = Client('http://localhost:8080/sse/'); print('FastMCP conectado')"],
      "env": {
        "FASTMCP_URL": "http://localhost:8080/sse/"
      }
    }
  }
}
```

## 🚀 **Processo de Instalação**

### **Passo 1: Instalar FastMCP**
```bash
pip install fastmcp
```

### **Passo 2: Criar Estrutura de Arquivos**
```bash
mkdir -p /home/ec2-user/bia/fastmcp-server
mkdir -p /home/ec2-user/bia/scripts
```

### **Passo 3: Implementar Servidor FastMCP**
- Criar arquivo `bia_fastmcp_server.py` com comandos customizados
- Dar permissões executáveis

### **Passo 4: Implementar Scripts de Automação**
- Criar `start-fastmcp.sh` para inicialização
- Criar `autostart-fastmcp.sh` para auto-start
- Criar comando `qbia` automatizado

### **Passo 5: Atualizar Configuração MCP**
- Fazer backup do `mcp.json` original
- Adicionar configuração `bia-fastmcp`

### **Passo 6: Configurar Auto-start**
```bash
echo "source /home/ec2-user/bia/scripts/autostart-fastmcp.sh" >> ~/.bashrc
```

## 🧪 **Testes e Validação**

### **Teste 1: Inicialização Manual**
```bash
/home/ec2-user/bia/scripts/start-fastmcp.sh
# Deve mostrar: FastMCP iniciado com sucesso (PID: XXXX)
```

### **Teste 2: Comando QBIA**
```bash
qbia
# Deve carregar 4 MCP servers e iniciar Amazon Q
```

### **Teste 3: Comandos FastMCP**
```bash
# Via Amazon Q:
"Liste as instâncias EC2"
"Me dê informações sobre o projeto BIA"
"Verifique o status do cluster ECS"
```

### **Teste 4: Auto-start**
```bash
# Fazer logout/login SSH
# FastMCP deve iniciar automaticamente
```

## 📊 **Monitoramento e Logs**

### **Verificar Status**
```bash
# Processo FastMCP
ps aux | grep fastmcp

# PID file
cat /tmp/bia-fastmcp.pid

# Logs
tail -f /tmp/bia-fastmcp.log
```

### **Verificar Conectividade**
```bash
# Endpoint HTTP
curl http://localhost:8080/sse/

# Porta em uso
netstat -tuln | grep :8080
```

## 🔧 **Troubleshooting**

### **Problema: FastMCP não inicia**
```bash
# Verificar se porta está livre
netstat -tuln | grep :8080

# Verificar logs
cat /tmp/bia-fastmcp.log

# Reiniciar manualmente
pkill -f fastmcp
/home/ec2-user/bia/scripts/start-fastmcp.sh
```

### **Problema: Amazon Q não carrega FastMCP**
```bash
# Verificar mcp.json
cat /home/ec2-user/bia/.amazonq/mcp.json

# Verificar se FastMCP está rodando
curl http://localhost:8080/sse/

# Restaurar backup se necessário
cp /home/ec2-user/bia/.amazonq/mcp.json.backup /home/ec2-user/bia/.amazonq/mcp.json
```

## 🏆 **Benefícios Obtidos**

### **✅ Funcionalidades**
- Comandos AWS customizados específicos do projeto BIA
- Integração perfeita com sistema MCP existente
- Automação completa sem configuração manual

### **✅ Operacional**
- Zero downtime na implementação
- Rollback simples via backup automático
- Coexistência com sistema tradicional

### **✅ Desenvolvimento**
- Flexibilidade para criar comandos específicos
- Aprendizado sobre protocolo MCP
- Base para futuras customizações

## 🔄 **Rollback**

### **Para Reverter a Implementação:**
```bash
# 1. Parar FastMCP
pkill -f fastmcp

# 2. Restaurar mcp.json original
cp /home/ec2-user/bia/.amazonq/mcp.json.backup /home/ec2-user/bia/.amazonq/mcp.json

# 3. Remover auto-start (opcional)
# Editar ~/.bashrc e remover linha do autostart-fastmcp.sh

# 4. Remover arquivos (opcional)
rm -rf /home/ec2-user/bia/fastmcp-server
rm -rf /home/ec2-user/bia/scripts/start-fastmcp.sh
rm /home/ec2-user/bia/qbia
```

## 📈 **Próximos Passos**

### **Melhorias Futuras**
- Adicionar mais comandos customizados conforme necessidade
- Implementar cache para comandos AWS frequentes
- Adicionar métricas e monitoramento avançado
- Integrar com outros serviços AWS

### **Comandos Sugeridos**
- `deploy_bia_application(version)` - Deploy automatizado
- `rollback_bia_deployment(revision)` - Rollback específico
- `get_bia_metrics()` - Métricas da aplicação
- `backup_bia_database()` - Backup do banco

---

**Implementado em:** 05/08/2025  
**Versão:** 1.0  
**Status:** Produção  
**Autor:** Amazon Q + Usuário BIA
