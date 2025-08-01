# 🤖 Sistema QBIA - Contexto Automático Completo

## 🎯 **Objetivo**

Quando você digitar `qbia`, o Amazon Q deve automaticamente ler todos os arquivos .md do projeto BIA e ficar completamente contextualizado, sabendo exatamente onde paramos nas conversas anteriores.

## ⚙️ **Como Funciona**

### **1. Comando `qbia`**
```bash
qbia  # Executa contexto automático completo
```

### **2. O que acontece automaticamente:**
1. **Navega** para `/home/ec2-user/bia`
2. **Ativa MCP servers** (filesystem + ECS + database)
3. **Copia** configuração completa para `mcp.json`
4. **Inicia Amazon Q** com acesso a todos os arquivos
5. **Amazon Q deve ler** automaticamente `LEIA-AUTOMATICAMENTE.md`
6. **Amazon Q deve ler** todos os arquivos .md listados

## 📚 **Arquivos que Amazon Q deve ler automaticamente:**

### **Regras Críticas:**
- `.amazonq/rules/dockerfile.md` - Regras para Dockerfiles
- `.amazonq/rules/infraestrutura.md` - Regras de infraestrutura
- `.amazonq/rules/pipeline.md` - Regras de pipeline

### **Contexto Base:**
- `AmazonQ.md` - Contexto geral do projeto
- `README.md` - Informações básicas
- `docs/README.md` - Documentação adicional
- `scripts_evento/README.md` - Scripts do evento

### **Histórico Completo:**
- `historico-conversas-amazonq.md` - **CRÍTICO:** Todas as conversas anteriores

### **Guias de Implementação:**
- `guia-criacao-ec2-bia.md` - Criação de EC2
- `guia-completo-ecs-bia.md` - Infraestrutura ECS
- `guia-mcp-servers-bia.md` - MCP servers
- `guia-script-deploy-versionado.md` - Deploy versionado

### **Status Atual:**
- `RESUMO-INFRAESTRUTURA-BIA.md` - **CRÍTICO:** Status atual da infraestrutura
- `DESAFIO-2-RESUMO-USUARIO.md` - Resumo estruturado
- `VERIFICACAO-DESAFIO-2.md` - Verificação completa
- `GUIA-DEPLOY-VERSIONADO.md` - Sistema de deploy
- `CONTEXTO-RAPIDO.md` - Referência rápida

### **Arquivos de Contexto e Sistema:**
- `.amazonq/CONTEXTO-INICIAL.md` - Lista de contexto inicial
- `CONTEXTO-AUTOMATICO.md` - Instrução de contexto automático
- `LEIA-AUTOMATICAMENTE.md` - Instrução principal para Amazon Q
- `SISTEMA-QBIA-CONTEXTO-AUTOMATICO.md` - Esta documentação

## 🔧 **MCP Servers Ativados**

### **Filesystem MCP:**
- **Função:** Acesso a todos os arquivos do projeto
- **Comando:** `npx -y @modelcontextprotocol/server-filesystem`
- **Diretório:** `/home/ec2-user/bia`

### **ECS MCP:**
- **Função:** Análise especializada de recursos ECS
- **Comando:** `uvx --from awslabs-ecs-mcp-server ecs-mcp-server`
- **Configuração:** Read-only, sem dados sensíveis

### **Database MCP:**
- **Função:** Conexão direta com RDS PostgreSQL
- **Comando:** `docker run -i --rm mcp/postgres`
- **Conexão:** RDS `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432`

## ✅ **Resultado Esperado**

Após executar `qbia`, Amazon Q deve:

### **Conhecer completamente:**
- ✅ **Projeto BIA:** Versão 3.2.0, bootcamp 28/07-03/08/2025
- ✅ **Infraestrutura atual:** Status (economia/ativo), recursos AWS
- ✅ **Histórico completo:** Todas as 12 conversas anteriores
- ✅ **Implementações:** Deploy versionado, MCP servers, scripts
- ✅ **Regras:** Dockerfile, infraestrutura, pipeline
- ✅ **Onde paramos:** Última conversa e próximos passos

### **Estar pronto para:**
- ✅ Continuar de onde paramos
- ✅ Usar ferramentas especializadas (ECS, Database)
- ✅ Seguir regras e filosofia do projeto
- ✅ Não pedir explicações sobre contexto

## 🚨 **Instruções para Amazon Q**

### **PROCESSO OBRIGATÓRIO:**
1. **Ler imediatamente** o arquivo `LEIA-AUTOMATICAMENTE.md`
2. **Ler todos** os arquivos .md listados
3. **Processar** todo o contexto e histórico
4. **Confirmar** que está contextualizado
5. **Estar pronto** para continuar

### **NÃO FAZER:**
- ❌ Pedir para usuário explicar contexto
- ❌ Perguntar sobre histórico anterior
- ❌ Solicitar informações já documentadas
- ❌ Começar "do zero"

### **FAZER:**
- ✅ Ler automaticamente todos os arquivos
- ✅ Processar contexto completo
- ✅ Confirmar contextualização
- ✅ Continuar de onde paramos

## 🎉 **Teste do Sistema**

### **Para testar:**
```bash
qbia
```

### **Amazon Q deve responder algo como:**
```
🤖 Contexto completo carregado! 

✅ Li todos os arquivos .md do projeto BIA (21 arquivos)
✅ Histórico de 12 conversas processado
✅ Status atual: [MODO ECONOMIA/ATIVO]
✅ Última implementação: [Deploy versionado/MCP servers/etc]
✅ Pronto para continuar de onde paramos

Como posso ajudar? Vejo que na última conversa estávamos...
```

## 🔄 **Comandos Alternativos**

```bash
# Contexto completo (recomendado)
qbia

# Apenas ECS
qecs

# Apenas Database  
qdb

# Sem MCP (padrão)
qclean
```

## 📝 **Arquivos do Sistema**

- `LEIA-AUTOMATICAMENTE.md` - Instrução principal para Amazon Q
- `SISTEMA-QBIA-CONTEXTO-AUTOMATICO.md` - Esta documentação
- `.amazonq/mcp-bia-completo.json` - Configuração MCP completa
- `~/.bashrc` - Alias qbia configurado

## 🎯 **Objetivo Final**

**Eliminar a necessidade de explicar contexto a cada nova sessão.**

Quando você digitar `qbia`, Amazon Q deve automaticamente saber:
- Quem você é
- O que é o projeto BIA
- Tudo que foi implementado
- Onde paramos
- O que fazer a seguir

**Resultado:** Continuidade perfeita entre sessões, como se fosse a mesma conversa contínua.

---

*Criado em: 01/08/2025*  
*Sistema implementado e testado*  
*Pronto para uso com `qbia`*
