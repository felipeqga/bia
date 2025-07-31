# 🤖 CONTEXTO RÁPIDO - Projeto BIA

## 📊 **Status Atual (31/07/2025)**
- **Modo:** ECONOMIA ATIVADA (~$8.50/mês economia)
- **Cluster ECS:** PARADO (desired-capacity: 0)
- **RDS:** ATIVO (dados preservados)
- **Aplicação:** OFFLINE

## 🤖 **Amazon Q com Contexto Completo**
```bash
qbia    # RECOMENDADO: Filesystem + ECS + Database + Regras + Contexto
qecs    # Só ECS especializado
qdb     # Só Database
qclean  # Sem MCP
```

## 🚀 **Comandos Essenciais**

### **Reativar Aplicação:**
```bash
./iniciar-cluster-completo.sh  # ~5-6 minutos
```

### **Parar para Economia:**
```bash
./parar-cluster-completo.sh    # Economia imediata
```

### **Deploy Versionado:**
```bash
./deploy-versioned.sh deploy   # Nova versão
./deploy-versioned.sh rollback # Voltar versão
```

## 📋 **Arquivos de Contexto (Carregados automaticamente com qbia)**
- **Regras:** `.amazonq/rules/dockerfile.md`, `infraestrutura.md`, `pipeline.md`
- **Base:** `AmazonQ.md`, `README.md`, `docs/README.md`
- **Histórico:** `historico-conversas-amazonq.md`
- **Guias:** `guia-completo-ecs-bia.md`, `guia-criacao-ec2-bia.md`
- **Status:** `RESUMO-INFRAESTRUTURA-BIA.md`
- **Deploy:** `guia-script-deploy-versionado.md`

## 🔧 **Recursos AWS**
- **RDS:** `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432`
- **ECR:** `387678648422.dkr.ecr.us-east-1.amazonaws.com/bia`
- **Cluster:** `cluster-bia` (PARADO)
- **ASG:** `Infra-ECS-Cluster-cluster-bia-581e3f53-ECSAutoScalingGroup-bFQW9Kb1APvu`

## ⚠️ **Lembrar**
- **IP dinâmico:** Muda a cada reativação
- **Dockerfile:** Atualizar IP para deploys
- **Dados:** Sempre preservados no RDS
- **Economia:** Ativa quando cluster parado
- **Filosofia BIA:** Simplicidade acima de complexidade
