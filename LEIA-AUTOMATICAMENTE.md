# 🤖 INSTRUÇÃO AUTOMÁTICA PARA AMAZON Q

## ⚠️ **LEIA IMEDIATAMENTE TODOS OS ARQUIVOS .MD DO PROJETO BIA**

Quando o usuário executar `qbia`, você deve **AUTOMATICAMENTE** ler todos os 39 arquivos .md listados abaixo para ter contexto completo:

### **🔧 Regras de Configuração (9 arquivos) - CRÍTICAS:**
- `/home/ec2-user/bia/.amazonq/rules/atualizacao-leitura-automatica.md`
- `/home/ec2-user/bia/.amazonq/rules/desafio-3-correcao-ia.md`
- `/home/ec2-user/bia/.amazonq/rules/dockerfile.md`
- `/home/ec2-user/bia/.amazonq/rules/infraestrutura.md`
- `/home/ec2-user/bia/.amazonq/rules/pipeline.md`
- `/home/ec2-user/bia/.amazonq/rules/codepipeline-setup.md`
- `/home/ec2-user/bia/.amazonq/rules/troubleshooting.md`
- `/home/ec2-user/bia/.amazonq/CONTEXTO-INICIAL.md`
- `/home/ec2-user/bia/.amazonq/REFINAMENTOS.md`

### **📚 Documentação Base (4 arquivos):**
- `/home/ec2-user/bia/AmazonQ.md`
- `/home/ec2-user/bia/README.md`
- `/home/ec2-user/bia/docs/README.md`
- `/home/ec2-user/bia/scripts_evento/README.md`

### **📖 Histórico e Guias (8 arquivos):**
- `/home/ec2-user/bia/historico-conversas-amazonq.md`
- `/home/ec2-user/bia/guia-criacao-ec2-bia.md`
- `/home/ec2-user/bia/guia-completo-ecs-bia-desafio-2.md`
- `/home/ec2-user/bia/guia-mcp-servers-bia.md`
- `/home/ec2-user/bia/guia-script-deploy-versionado.md`
- `/home/ec2-user/bia/guia-desafio-3-corrigido.md`
- `/home/ec2-user/bia/historico-desafio-3-zero-downtime.md`
- `/home/ec2-user/bia/historico-descoberta-console-aws-vs-cli.md`

### **📊 Status e Verificação (1 arquivo):**
- `/home/ec2-user/bia/CONTEXTO-RAPIDO.md`

### **🤖 Arquivos de Contexto e Sistema (9 arquivos):**
- `/home/ec2-user/bia/.amazonq/context/desafio-3-ecs-alb.md`
- `/home/ec2-user/bia/.amazonq/context/desafio-3-route53-https.md`
- `/home/ec2-user/bia/.amazonq/context/iam-permissions-discovery.md`
- `/home/ec2-user/bia/.amazonq/context/permissoes-completas-desafio-3.md`
- `/home/ec2-user/bia/.amazonq/context/codepipeline-troubleshooting-permissions.md`
- `/home/ec2-user/bia/CONTEXTO-AUTOMATICO.md`
- `/home/ec2-user/bia/CONTEXTO-COMPLETO-CARREGADO.md`
- `/home/ec2-user/bia/LEIA-AUTOMATICAMENTE.md`
- `/home/ec2-user/bia/SISTEMA-QBIA-CONTEXTO-AUTOMATICO.md`

### **🎯 DESAFIO-2 (3 arquivos):**
- `/home/ec2-user/bia/RESUMO-INFRAESTRUTURA-BIA.md`
- `/home/ec2-user/bia/DESAFIO-2-RESUMO-USUARIO.md`
- `/home/ec2-user/bia/VERIFICACAO-DESAFIO-2.md`

### **🎯 DESAFIO-3 (4 arquivos):**
- `/home/ec2-user/bia/.amazonq/context/desafio-3-ecs-alb.md`
- `/home/ec2-user/bia/.amazonq/context/troubleshooting-ecs-alb.md`
- `/home/ec2-user/bia/.amazonq/context/erros-criacao-cluster-ecs.md`
- `/home/ec2-user/bia/GUIA-DEPLOY-VERSIONADO.md`

### **🔍 Troubleshooting (1 arquivo):**
- `/home/ec2-user/bia/troubleshooting-session-2025-08-02.md`

---

## 🎯 **PROCESSO AUTOMÁTICO:**

1. **IMEDIATAMENTE** após iniciar com `qbia`
2. **LER TODOS** os 38 arquivos .md listados acima
3. **PROCESSAR** todo o contexto e histórico
4. **CONFIRMAR** que está contextualizado
5. **ESTAR PRONTO** para continuar de onde paramos

## ✅ **CONFIRMAÇÃO OBRIGATÓRIA:**

Após ler todos os arquivos, você deve confirmar:
- ✅ Contexto completo carregado (38 arquivos .md lidos)
- ✅ Histórico de conversas processado
- ✅ Status atual da infraestrutura conhecido
- ✅ Regras e filosofia do projeto compreendidas
- ✅ Pronto para continuar de onde paramos

## 🚀 **RESULTADO ESPERADO:**

Você deve estar completamente contextualizado sobre:
- **Projeto BIA:** Versão 4.2.0, bootcamp 28/07-03/08/2025
- **Infraestrutura:** Status atual (modo economia ou ativo)
- **Conversas anteriores:** Tudo que foi discutido e implementado
- **Próximos passos:** Onde paramos e o que fazer

**IMPORTANTE:** Não peça para o usuário explicar o contexto. Você deve ler automaticamente e ficar contextualizado.

## 📊 **TOTAL DE ARQUIVOS: 39 ARQUIVOS .MD**

**Verificação:** `find /home/ec2-user/bia -name "*.md" -type f -not -path "*/node_modules/*" | wc -l` deve retornar 39

---

## 🎯 **CONHECIMENTO ESPERADO APÓS LEITURA:**

### **📋 Projeto BIA:**
- **Versão:** 4.2.0
- **Status:** DESAFIO-2 e DESAFIO-3 100% implementados
- **Modo atual:** ECONOMIA (recursos deletados, ~$32/mês economizados)
- **Filosofia:** Simplicidade para alunos em aprendizado

### **🏗️ Infraestrutura:**
- **Preservado:** RDS PostgreSQL + ECR + Documentação
- **Deletado:** ALB + 2x EC2 t3.micro + ECS Tasks
- **Recriação:** Documentação completa disponível

### **🔧 Recursos AWS Ativos:**
- **RDS:** `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432`
- **ECR:** `387678648422.dkr.ecr.us-east-1.amazonaws.com/bia`
- **Variáveis confirmadas:** DB_USER, DB_PWD, DB_HOST, DB_PORT

### **🚀 Sistemas Implementados:**
- **Deploy versionado:** Sistema completo com rollback
- **MCP Servers:** ECS + Database especializados
- **Otimizações:** 31% melhoria no tempo de deploy comprovada
- **Scripts automáticos:** Reativação e parada para economia

---

*Atualizado em: 04/08/2025 01:30 UTC*  
*Total de arquivos: 37 arquivos .md organizados por categoria*  
*Sistema: QBIA funcionando perfeitamente*  
*Nova adição: Documentação completa Route 53 + HTTPS*