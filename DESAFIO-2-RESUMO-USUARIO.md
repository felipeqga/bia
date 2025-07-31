# DESAFIO-2 - RESUMO ESTRUTURADO DO USUÁRIO

## 📋 **Checklist Completo de Implementação**

### **🔒 SECURITY GROUPS**

#### **SecurityGroup-1: bia-web**
- **Inbound:** HTTP (80) ← 0.0.0.0/0
- **Outbound:** All Traffic ← 0.0.0.0/0

#### **SecurityGroup-2: bia-db**
- **Inbound:** PostgreSQL (5432) ← bia-web
- **Outbound:** All Traffic ← 0.0.0.0/0
- **OBS:** Dar permissão ao bia-db para que o bia-dev consiga acesso

---

### **🗄️ BANCO RDS**

**Verificar se o banco RDS está criado:**
- **Free Tier:** ✅
- **Security Group:** bia-db
- **Performance Insights:** ❌ Desmarcar
- **Availability Zone:** us-east-1a
- **Public Access:** NO
- **Instance Class:** db.t3.micro
- **Storage Type:** GP2 20GB
- **Automated Backups:** NO
- **Database Name/Identifier:** bia
- **Senha:** Kgegwlaj6mAIxzHaEqgo
- **Endpoint:** bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com

---

### **🐳 ECR**

**Verificar se o ECR está criado:**
- **Repository Name:** bia
- **Image Tag Mutability:** MUTABLE
- **Encryption:** AES-256
- **URI Gerada:** 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia

**Scripts:**
- Verificar pasta `scripts/ecs/unix/` os arquivos: `build.sh` e `deploy.sh`
- Copiar para pasta raiz do projeto `bia`
- **Alterar build.sh:** 
  - `ECR_REGISTRY="SEU_REGISTRY"` 
  - Substituir por: `ECR_REGISTRY="387678648422.dkr.ecr.us-east-1.amazonaws.com"`

---

### **🚀 ECS CLUSTER**

**Verificar se tem cluster criado:**
- **Cluster Name:** cluster-bia
- **Infrastructure:** Amazon EC2 instances
- **Provisioning Model:** On-demand
- **Instance Type:** t3.micro
- **Desired Capacity:** Minimum=1, Maximum=1
- **Subnets:** us-east-1a, us-east-1b
- **Security Group:** bia-web
- **OBS:** Neste primeiro momento fica sem o "capacity provider"

---

### **📋 TASK DEFINITION**

**Verificar se tem task definition criada:**
- **Task Definition Family Name:** task-def-bia
- **Infrastructure Requirements:** Amazon EC2 instances
- **Network Mode:** bridge

**Container Details:**
- **Name:** bia
- **Image URI:** 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest
- **Port Mapping:**
  - Host Port: 80
  - Container Port: 8080
  - Protocol: TCP
  - Port Name: porta-80
  - App Protocol: HTTP

**Resource Allocation:**
- **CPU:** 1 vCPU
- **Memory Hard Limit:** 3GB
- **Memory Soft Limit:** 0.4GB

**Environment Variables:**
```
DB_USER=postgres
DB_PWD=Kgegwlaj6mAIxzHaEqgo
DB_HOST=bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
DB_PORT=5432
```

---

### **🔄 CREATE SERVICE**

**Verificar se tem service criada:**
- **Service Name:** service-bia
- **Existing Cluster:** cluster-bia
- **Compute Options:** Launch type
- **Launch Type:** EC2
- **Scheduling Strategy:** Replica
- **Desired Tasks:** 1
- **Deployment Failure Detection:** Todos desmarcados

---

### **🔧 CONFIGURAÇÕES CRÍTICAS**

#### **OBS-1: Deployment Configuration**
Alterar em "Deployment controller type" → "Deployment Strategy" → "Rolling Update":
- **Minimum running tasks:** 0% (não 100%)
- **Maximum running tasks:** 100% (não 200%)

**Motivo:** Evita erro de porta ocupada durante deployments.

#### **OBS-2: Script deploy.sh**
Alterar arquivo `deploy.sh` com novos parâmetros:
```bash
# ANTES
aws ecs update-service --cluster [SEU_CLUSTER] --service [SEU_SERVICE] --force-new-deployment

# DEPOIS  
aws ecs update-service --cluster cluster-bia --service service-bia --force-new-deployment
```

---

### **🗄️ ATUALIZAR COMPOSE E MIGRATIONS**

**Atualizar dados no compose.yml:**
```yaml
environment:
  DB_USER: postgres
  DB_PWD: Kgegwlaj6mAIxzHaEqgo
  DB_HOST: bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
  DB_PORT: 5432
```

**Executar Migrations no RDS:**
```bash
docker compose exec server bash -c 'npx sequelize db:migrate'
```

---

## ✅ **CHECKLIST DE VALIDAÇÃO**

- [ ] Security Groups criados (bia-web, bia-db)
- [ ] RDS PostgreSQL funcionando
- [ ] ECR repository configurado
- [ ] Scripts build.sh/deploy.sh copiados e corrigidos
- [ ] ECS Cluster ativo
- [ ] Task Definition configurada
- [ ] ECS Service rodando
- [ ] Deployment configuration corrigida (0%/100%)
- [ ] Compose.yml atualizado com RDS
- [ ] Migrations executadas
- [ ] Aplicação acessível via HTTP

---

## 🎯 **RESULTADO ESPERADO**

**Aplicação BIA funcionando em:**
- **URL:** http://IP_PUBLICO_ECS
- **API:** http://IP_PUBLICO_ECS/api/versao

**Com infraestrutura:**
- ✅ ECS Cluster com instância EC2 t3.micro
- ✅ RDS PostgreSQL com dados persistentes
- ✅ ECR com imagem da aplicação
- ✅ Scripts de deploy automatizados
- ✅ Deployment sem conflito de porta

---

*Resumo criado pelo usuário - Implementado com sucesso em 31/07/2025*
