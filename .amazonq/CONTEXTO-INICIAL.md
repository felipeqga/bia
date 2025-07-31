# 🤖 CONTEXTO INICIAL - Amazon Q BIA

## 📋 **ARQUIVOS DE CONTEXTO OBRIGATÓRIOS**

### **🔧 Regras do Projeto (SEMPRE ler primeiro):**
- `/home/ec2-user/bia/.amazonq/rules/dockerfile.md` - Regras para Dockerfiles
- `/home/ec2-user/bia/.amazonq/rules/infraestrutura.md` - Regras de infraestrutura
- `/home/ec2-user/bia/.amazonq/rules/pipeline.md` - Regras de pipeline

### **📚 Documentação Base:**
- `/home/ec2-user/bia/AmazonQ.md` - Contexto e análise do projeto
- `/home/ec2-user/bia/README.md` - Informações básicas do projeto
- `/home/ec2-user/bia/docs/README.md` - Documentação técnica
- `/home/ec2-user/bia/scripts_evento/README.md` - Scripts do evento

### **📖 Histórico e Guias:**
- `/home/ec2-user/bia/historico-conversas-amazonq.md` - Histórico completo
- `/home/ec2-user/bia/guia-criacao-ec2-bia.md` - Criação de EC2
- `/home/ec2-user/bia/guia-completo-ecs-bia.md` - Infraestrutura ECS
- `/home/ec2-user/bia/RESUMO-INFRAESTRUTURA-BIA.md` - Status executivo
- `/home/ec2-user/bia/DESAFIO-2-RESUMO-USUARIO.md` - Resumo do usuário
- `/home/ec2-user/bia/guia-mcp-servers-bia.md` - Guia MCP servers
- `/home/ec2-user/bia/guia-script-deploy-versionado.md` - Deploy versionado

## 🎯 **FILOSOFIA DO PROJETO BIA**
- **Público-alvo:** Alunos em aprendizado
- **Abordagem:** Simplicidade acima de complexidade
- **Objetivo:** Facilitar compreensão de quem está na etapa inicial

## 📊 **STATUS ATUAL (31/07/2025)**
- **Modo:** ECONOMIA ATIVADA
- **Cluster ECS:** PARADO (desired-capacity: 0)
- **RDS:** ATIVO (dados preservados)
- **Economia:** ~$8.50/mês

## 🚀 **COMANDOS ESSENCIAIS**
- `./iniciar-cluster-completo.sh` - Reativar aplicação
- `./parar-cluster-completo.sh` - Parar para economia
- `./deploy-versioned.sh deploy` - Deploy versionado

## 🛠️ **RECURSOS AWS PRINCIPAIS**
- **RDS:** `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432`
- **ECR:** `387678648422.dkr.ecr.us-east-1.amazonaws.com/bia`
- **Cluster:** `cluster-bia`
- **ASG:** `Infra-ECS-Cluster-cluster-bia-581e3f53-ECSAutoScalingGroup-bFQW9Kb1APvu`

## ⚠️ **PONTOS CRÍTICOS**
- **IP dinâmico:** Muda a cada reativação do cluster
- **Dockerfile:** Precisa atualizar IP para deploys
- **Dados:** Sempre preservados no RDS
- **Regras:** Seguir sempre as regras em `.amazonq/rules/`
