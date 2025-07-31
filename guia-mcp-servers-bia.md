# Guia MCP Servers - Projeto BIA

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

### **Passo 1: Escolher MCP Server**

#### **Para Análise ECS:**
```bash
cd /home/ec2-user/bia/.amazonq
cp mcp-ecs.json mcp.json
```

#### **Para Análise Database:**
```bash
cd /home/ec2-user/bia/.amazonq
cp mcp-db.json mcp.json
```

### **Passo 2: Reiniciar Amazon Q**
1. Finalizar conversa atual
2. Inicializar nova conversa
3. Verificar aviso MCP no topo da tela

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
rm /home/ec2-user/bia/.amazonq/mcp.json
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
```bash
# Verificar arquivo existe
ls -la /home/ec2-user/bia/.amazonq/mcp.json

# Verificar sintaxe JSON
cat /home/ec2-user/bia/.amazonq/mcp.json | jq .

# Verificar logs
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
cd /home/ec2-user/bia/.amazonq
rm -f mcp.json
# Reiniciar Amazon Q
```

## 📋 **Estrutura de Arquivos**

```
/home/ec2-user/bia/.amazonq/
├── mcp-ecs.json     # ECS MCP Server config
├── mcp-db.json      # Database MCP Server config
├── mcp.json         # Arquivo ativo (quando existe)
└── rules/           # Regras de contexto
    ├── dockerfile.md
    ├── infraestrutura.md
    └── pipeline.md
```

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
