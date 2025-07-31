# Guia MCP Servers - Projeto BIA

## ⚠️ **DESCOBERTA CRÍTICA - Amazon Q CLI e Dot Folders**

### **Problema Identificado:**
O Amazon Q CLI **NÃO consegue carregar** arquivos `mcp.json` que estão dentro de pastas que começam com "." (dot folders).

### **Comportamento Observado:**

#### **❌ NÃO FUNCIONA:**
```bash
# Arquivo dentro de pasta .amazonq
/home/ec2-user/bia/.amazonq/mcp.json

# Executar Amazon Q CLI
cd /home/ec2-user/bia
q
# Resultado: MCP server NÃO é carregado
```

#### **✅ FUNCIONA:**
```bash
# Arquivo na raiz do projeto
/home/ec2-user/bia/mcp.json

# Executar Amazon Q CLI
cd /home/ec2-user/bia
q
# Resultado: MCP server É carregado automaticamente
```

### **Causa Provável:**
- **Convenção Unix:** Arquivos/pastas que começam com "." são considerados ocultos
- **Amazon Q CLI:** Provavelmente ignora dot folders por design de segurança
- **Solução:** Manter arquivo ativo na raiz do projeto

### **Estratégia Recomendada:**
1. **Templates:** Manter configurações em `.amazonq/` (organização)
2. **Arquivo ativo:** Copiar para raiz quando necessário
3. **Limpeza:** Remover `mcp.json` da raiz quando não precisar

### **Comandos para Alternar:**
```bash
# Ativar ECS MCP
cd /home/ec2-user/bia
cp .amazonq/mcp-ecs.json mcp.json && q

# Ativar Database MCP
cd /home/ec2-user/bia
cp .amazonq/mcp-db.json mcp.json && q

# Ativar MCP Combinado
cd /home/ec2-user/bia
cp .amazonq/mcp-combined.json mcp.json && q

# Desativar MCP
cd /home/ec2-user/bia
rm mcp.json && q
```

---

## 🎯 **Visão Geral**

O projeto BIA possui **MCP (Model Context Protocol) servers** especializados que fornecem ferramentas avançadas para análise de infraestrutura AWS e banco de dados.

## 📋 **MCP Servers Disponíveis**

### **1. ECS MCP Server**
- **Arquivo:** `mcp-ecs.json`
- **Server:** `awslabs.ecs-mcp-server`
- **Função:** Análise especializada de recursos ECS
- **Tools disponíveis:**
  - `ecs_resouce_management`
  - Análise de clusters, services, tasks
  - Monitoramento de deployment
  - Troubleshooting automatizado

### **2. Database MCP Server**
- **Arquivo:** `mcp-db.json`
- **Server:** `postgres`
- **Função:** Conexão direta com RDS PostgreSQL
- **Capabilities:**
  - Queries diretas no banco
  - Análise de schema
  - Monitoramento de performance
  - Backup/restore operations

## 🔧 **Configurações**

### **ECS MCP Server (`mcp-ecs.json`):**
```json
{
  "mcpServers": {
    "awslabs.ecs-mcp-server": {
      "command": "uvx",
      "args": ["--from", "awslabs-ecs-mcp-server", "ecs-mcp-server"],
      "env": {        
        "FASTMCP_LOG_LEVEL": "ERROR",
        "FASTMCP_LOG_FILE": "/tmp/ecs-mcp-server.log",
        "ALLOW_WRITE": "false",
        "ALLOW_SENSITIVE_DATA": "false"
      }
    }
  }
}
```

**Características:**
- **Read-only:** Não permite modificações
- **Seguro:** Não expõe dados sensíveis
- **Logging:** Erros em `/tmp/ecs-mcp-server.log`

### **Database MCP Server (`mcp-db.json`):**
```json
{
  "mcpServers": {
    "postgres": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "mcp/postgres",
        "postgresql://postgres:Kgegwlaj6mAIxzHaEqgo@bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432/bia"
      ]
    }
  }
}
```

**Características:**
- **Conexão direta:** RDS PostgreSQL
- **Containerizado:** Usa Docker para isolamento
- **Temporário:** Container removido após uso

## 🚀 **Como Usar**

### ⚠️ **PROBLEMA CRÍTICO DESCOBERTO**

**O Amazon Q CLI NÃO carrega MCP servers de pastas que começam com "." (dot files/folders)**

- **❌ NÃO FUNCIONA:** `/home/ec2-user/bia/.amazonq/mcp.json`
- **✅ FUNCIONA:** `/home/ec2-user/bia/mcp.json` (fora da pasta .amazonq)

### **Passo 1: Escolher MCP Server**

#### **Para Análise ECS:**
```bash
cd /home/ec2-user/bia
cp .amazonq/mcp-ecs.json mcp.json
```

#### **Para Análise Database:**
```bash
cd /home/ec2-user/bia
cp .amazonq/mcp-db.json mcp.json
```

#### **Para MCP Combinado (ECS + Database):**
```bash
cd /home/ec2-user/bia
cp .amazonq/mcp-combined.json mcp.json
```

### **Passo 2: Executar Amazon Q**
```bash
cd /home/ec2-user/bia
q  # Amazon Q CLI carregará o mcp.json automaticamente
```

### **Passo 3: Verificar MCP Server Ativo**
- Verificar se aparecem ferramentas como `awslabs.ecs-mcp-server___*` ou `postgres___query`
- Se não aparecer, o MCP server não foi carregado

### **Passo 3: Usar Ferramentas Especializadas**

#### **Com ECS MCP Server:**
```
Pergunta: "Analise a comunicação de rede do cluster-bia"
Tool usado: ecs_resouce_management
```

#### **Com Database MCP Server:**
```
Pergunta: "Verifique o schema do banco bia"
Tool usado: postgres queries diretas
```

### **Passo 4: Voltar ao Padrão**
```bash
cd /home/ec2-user/bia
rm mcp.json  # Remove arquivo da raiz do projeto
# Reiniciar Amazon Q
```

## 📊 **Comparação de Ferramentas**

### **Sem MCP Server (Padrão):**
- **Tool:** `use_aws`
- **Abordagem:** AWS CLI genérico
- **Parâmetros:** Manuais e detalhados
- **Análise:** Manual, passo a passo

### **Com ECS MCP Server:**
- **Tool:** `ecs_resouce_management`
- **Abordagem:** Especializada em ECS
- **Parâmetros:** Simplificados
- **Análise:** Automatizada e otimizada

### **Com Database MCP Server:**
- **Tool:** `postgres`
- **Abordagem:** Conexão direta
- **Parâmetros:** SQL nativo
- **Análise:** Queries diretas no banco

## 🎯 **Casos de Uso**

### **Use ECS MCP Server quando:**
- ✅ Analisar performance de clusters
- ✅ Troubleshoot deployments
- ✅ Monitorar services e tasks
- ✅ Verificar configurações de rede ECS

### **Use Database MCP Server quando:**
- ✅ Executar queries complexas
- ✅ Analisar dados da aplicação
- ✅ Verificar integridade do banco
- ✅ Monitorar performance de queries

### **Use ferramentas padrão quando:**
- ✅ Configurar recursos AWS
- ✅ Gerenciar múltiplos serviços
- ✅ Fazer mudanças na infraestrutura
- ✅ Análise cross-service

## 🔍 **Troubleshooting**

### **MCP Server não carrega:**

#### **Problema mais comum: Arquivo na pasta .amazonq**
```bash
# ❌ ERRO: Arquivo na pasta que começa com "."
ls -la /home/ec2-user/bia/.amazonq/mcp.json

# ✅ SOLUÇÃO: Mover para raiz do projeto
cd /home/ec2-user/bia
cp .amazonq/mcp-ecs.json mcp.json  # ou mcp-db.json ou mcp-combined.json
```

#### **Verificações adicionais:**
```bash
# Verificar arquivo existe na raiz
ls -la /home/ec2-user/bia/mcp.json

# Verificar sintaxe JSON
cat /home/ec2-user/bia/mcp.json | jq .

# Verificar logs ECS MCP
tail -f /tmp/ecs-mcp-server.log
```

### **Erro de conexão Database:**
```bash
# Testar conectividade RDS
docker run --rm postgres:16.1 psql \
  "postgresql://postgres:Kgegwlaj6mAIxzHaEqgo@bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432/bia" \
  -c "SELECT 1;"
```

### **Voltar ao estado limpo:**
```bash
cd /home/ec2-user/bia
rm -f mcp.json  # Remove da raiz do projeto
# Reiniciar Amazon Q
```

## 📋 **Estrutura de Arquivos**

```
/home/ec2-user/bia/
├── mcp.json             # ✅ ARQUIVO ATIVO (quando existe) - RAIZ DO PROJETO
├── .amazonq/            # 📁 Pasta de configurações (templates)
│   ├── mcp-ecs.json     # Template ECS MCP Server
│   ├── mcp-db.json      # Template Database MCP Server
│   ├── mcp-combined.json # Template MCP Combinado
│   └── rules/           # Regras de contexto
│       ├── dockerfile.md
│       ├── infraestrutura.md
│       └── pipeline.md
└── (outros arquivos do projeto)
```

### ⚠️ **REGRA FUNDAMENTAL:**
- **Amazon Q CLI só carrega `mcp.json` da RAIZ do projeto**
- **Pastas que começam com "." são ignoradas pelo Amazon Q CLI**
- **Templates ficam em `.amazonq/` mas arquivo ativo deve estar na raiz**

## 🎉 **Benefícios dos MCP Servers**

### **Especialização:**
- Ferramentas otimizadas para cada contexto
- Análises mais profundas e precisas
- Menos parâmetros manuais necessários

### **Eficiência:**
- Respostas mais rápidas
- Menos chamadas de API
- Análise automatizada

### **Flexibilidade:**
- Troca dinâmica de contexto
- Múltiplas especializações disponíveis
- Configuração por projeto

---

## 🚀 **Próximos Passos**

1. **Testar ECS MCP Server** para análise de infraestrutura
2. **Testar Database MCP Server** para análise de dados
3. **Comparar resultados** com ferramentas padrão
4. **Documentar** casos de uso específicos

---

*Criado em: 31/07/2025 19:30 UTC*
*Baseado na descoberta dos MCP servers do projeto BIA*
