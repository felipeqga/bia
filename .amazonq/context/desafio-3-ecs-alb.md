# DESAFIO-3: ECS Cluster com Application Load Balancer (ALB)

## 📋 RESUMO EXECUTIVO
**Status:** ✅ CONCLUÍDO COM SUCESSO  
**Data:** 02/08/2025  
**Objetivo:** Implementar cluster ECS com ALB para alta disponibilidade  
**Resultado:** Aplicação BIA funcionando com 2 instâncias EC2 + ALB + RDS

---

## 🎯 ARQUITETURA IMPLEMENTADA

### **Componentes Criados:**
- **ECS Cluster:** cluster-bia-alb
- **Task Definition:** task-def-bia-alb:5 (versão final)
- **Service:** service-bia-alb (2 tasks desejadas)
- **ALB:** bia-1433396588.us-east-1.elb.amazonaws.com
- **Target Group:** tg-bia (health check: /api/versao)
- **Instâncias EC2:** 2x t3.micro (us-east-1a e us-east-1b)

### **Security Groups:**
- **bia-alb:** HTTP/HTTPS público (0.0.0.0/0)
- **bia-ec2:** All TCP do bia-alb
- **bia-db:** PostgreSQL:5432 do bia-ec2

---

## 🚨 PROBLEMAS IDENTIFICADOS E SOLUÇÕES

### ❌ **ERRO 1: IAM Role Incorreto**
**Problema:** Instâncias usando `ecsInstanceRole` em vez de `role-acesso-ssm`  
**Consequência:** Sem acesso SSM para troubleshooting  
**Solução:** Sempre usar `role-acesso-ssm` que tem permissões ECS + SSM  

```bash
# CORRETO:
--iam-instance-profile Name=role-acesso-ssm

# INCORRETO:
--iam-instance-profile Name=ecsInstanceRole
```

### ❌ **ERRO 2: Availability Zones Incompatíveis**
**Problema:** Instâncias EC2 em us-east-1d, ALB em us-east-1a/1b  
**Consequência:** Tasks unhealthy no Target Group  
**Solução:** Sempre verificar AZs do ALB antes de criar instâncias  

```bash
# VERIFICAR AZs DO ALB PRIMEIRO:
aws elbv2 describe-load-balancers --names "bia"

# CRIAR INSTÂNCIAS NAS AZs CORRETAS:
--subnet-id subnet-068e3484d05611445  # us-east-1a
--subnet-id subnet-0c665b052ff5c528d   # us-east-1b
```

### ❌ **ERRO 3: Variáveis de Ambiente RDS**
**Problema:** Senha incorreta do banco (postgres123 vs Kgegwlaj6mAIxzHaEqgo)  
**Consequência:** Endpoints que precisam do banco retornam HTML  
**Sintoma:** `/api/versao` funciona, `/api/usuarios` retorna HTML  

```json
// IMPORTANTE: SEMPRE PERGUNTAR as variáveis atuais do RDS!
// Estes valores MUDAM conforme o ambiente/tempo:
"environment": [
  {"name": "DB_HOST", "value": "PERGUNTAR_AO_USUARIO"},
  {"name": "DB_PORT", "value": "PERGUNTAR_AO_USUARIO"},
  {"name": "DB_USER", "value": "PERGUNTAR_AO_USUARIO"},
  {"name": "DB_PWD", "value": "PERGUNTAR_AO_USUARIO"},  // ← SEMPRE PERGUNTAR!
  {"name": "NODE_ENV", "value": "production"}
]

// Exemplo atual (válido até RDS ser recriado):
// DB_HOST: "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"
// DB_PWD: "Kgegwlaj6mAIxzHaEqgo"
```

---

## 🔧 PROCESSO CORRETO - PASSO A PASSO

### **PASSO 1: Verificar Infraestrutura Existente**
```bash
# Verificar ALB e suas AZs
aws elbv2 describe-load-balancers --names "bia"

# Verificar RDS
aws rds describe-db-instances --db-instance-identifier "bia"

# Verificar Security Groups
aws ec2 describe-security-groups --group-names "bia-alb" "bia-ec2" "bia-db"
```

### **PASSO 2: Criar Security Groups**
```bash
# bia-alb (público)
aws ec2 create-security-group --group-name bia-alb --description "ALB do projeto BIA"
aws ec2 authorize-security-group-ingress --group-name bia-alb --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name bia-alb --protocol tcp --port 443 --cidr 0.0.0.0/0

# bia-ec2 (recebe do ALB)
aws ec2 create-security-group --group-name bia-ec2 --description "EC2 instances do projeto BIA"
aws ec2 authorize-security-group-ingress --group-name bia-ec2 --protocol tcp --port 0-65535 --source-group bia-alb

# bia-db (recebe do EC2)
aws ec2 authorize-security-group-ingress --group-name bia-db --protocol tcp --port 5432 --source-group bia-ec2
```

### **PASSO 3: Criar ALB e Target Group**
```bash
# Criar ALB
aws elbv2 create-load-balancer --name bia --subnets subnet-068e3484d05611445 subnet-0c665b052ff5c528d --security-groups sg-081297c2a6694761b

# Criar Target Group
aws elbv2 create-target-group --name tg-bia --protocol HTTP --port 80 --vpc-id vpc-08b8e37ee6ff01860 --health-check-path /api/versao

# Modificar Target Group (deregistration delay)
aws elbv2 modify-target-group-attributes --target-group-arn xxx --attributes Key=deregistration_delay.timeout_seconds,Value=30

# Criar Listener
aws elbv2 create-listener --load-balancer-arn xxx --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=xxx
```

### **PASSO 4: Criar ECS Cluster**
```bash
aws ecs create-cluster --cluster-name cluster-bia-alb
```

### **PASSO 5: Lançar Instâncias EC2 (CORRIGIDO)**
```bash
# BUSCAR AMI ECS x86_64
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-ecs-hvm-*" "Name=state,Values=available" "Name=architecture,Values=x86_64" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)

# INSTÂNCIA US-EAST-1A
aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type t3.micro \
  --iam-instance-profile Name=role-acesso-ssm \
  --security-group-ids sg-00c1a082f04bc6709 \
  --subnet-id subnet-068e3484d05611445 \
  --user-data "#!/bin/bash
echo ECS_CLUSTER=cluster-bia-alb >> /etc/ecs/ecs.config
yum update -y
yum install -y ecs-init
service docker start
start ecs" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-ecs-instance-1a},{Key=Project,Value=BIA}]'

# INSTÂNCIA US-EAST-1B
aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type t3.micro \
  --iam-instance-profile Name=role-acesso-ssm \
  --security-group-ids sg-00c1a082f04bc6709 \
  --subnet-id subnet-0c665b052ff5c528d \
  --user-data "#!/bin/bash
echo ECS_CLUSTER=cluster-bia-alb >> /etc/ecs/ecs.config
yum update -y
yum install -y ecs-init
service docker start
start ecs" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-ecs-instance-1b},{Key=Project,Value=BIA}]'
```

### **PASSO 6: Criar Task Definition (CORRIGIDO)**
```bash
# Criar Log Group
aws logs create-log-group --log-group-name /ecs/task-def-bia-alb

# Registrar Task Definition
aws ecs register-task-definition --cli-input-json '{
  "family": "task-def-bia-alb",
  "networkMode": "bridge",
  "requiresCompatibilities": ["EC2"],
  "containerDefinitions": [{
    "name": "bia",
    "image": "387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest",
    "cpu": 1024,
    "memory": 3072,
    "memoryReservation": 409,
    "essential": true,
    "portMappings": [{
      "containerPort": 8080,
      "hostPort": 0,
      "protocol": "tcp",
      "name": "porta-aleatoria",
      "appProtocol": "http"
    }],
    "environment": [
      {"name": "DB_HOST", "value": "PERGUNTAR_AO_USUARIO"},
      {"name": "DB_PORT", "value": "PERGUNTAR_AO_USUARIO"},
      {"name": "DB_USER", "value": "PERGUNTAR_AO_USUARIO"},
      {"name": "DB_PWD", "value": "PERGUNTAR_AO_USUARIO"},
      {"name": "NODE_ENV", "value": "production"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/task-def-bia-alb",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}'
```

### **PASSO 7: Criar ECS Service**
```bash
aws ecs create-service \
  --cluster cluster-bia-alb \
  --service-name service-bia-alb \
  --task-definition task-def-bia-alb \
  --desired-count 2 \
  --launch-type EC2 \
  --deployment-configuration maximumPercent=100,minimumHealthyPercent=50 \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/9e999191b3d60e38,containerName=bia,containerPort=8080 \
  --placement-strategy type=spread,field=attribute:ecs.availability-zone
```

---

## 🔍 CHECKLIST DE TROUBLESHOOTING

### **Se ALB não responder:**
1. ✅ Verificar se instâncias estão nas AZs corretas do ALB
2. ✅ Verificar Security Groups (bia-alb → bia-ec2)
3. ✅ Verificar se Target Group está healthy
4. ✅ Verificar se instâncias se registraram no cluster ECS

### **Se API retornar HTML em vez de JSON:**
1. ✅ Verificar variáveis de ambiente do RDS na task definition
2. ✅ Verificar Security Group bia-db permite acesso do bia-ec2
3. ✅ Verificar logs da aplicação no CloudWatch
4. ✅ Testar `/api/versao` (não precisa banco) vs `/api/usuarios` (precisa banco)

### **Se não conseguir acessar instâncias:**
1. ✅ Verificar se IAM Role é `role-acesso-ssm`
2. ✅ Usar SSM Session Manager em vez de SSH
3. ✅ Verificar se instâncias têm conectividade com internet

---

## 📊 RECURSOS FINAIS CRIADOS

### **IDs dos Recursos:**
- **ALB:** bia-1433396588.us-east-1.elb.amazonaws.com
- **Target Group:** arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/9e999191b3d60e38
- **ECS Cluster:** cluster-bia-alb
- **Task Definition:** task-def-bia-alb:5
- **Service:** service-bia-alb
- **Security Groups:** 
  - bia-alb: sg-081297c2a6694761b
  - bia-ec2: sg-00c1a082f04bc6709
  - bia-db: sg-0d954919e73c1af79

### **Instâncias EC2 (Versão Final):**
- **us-east-1a:** i-0ce079b5c267180bd (role-acesso-ssm)
- **us-east-1b:** i-0778fcd843cd3ef5f (role-acesso-ssm)

---

## 🎯 LIÇÕES APRENDIDAS

### **1. Sempre Perguntar Variáveis RDS**
- **NUNCA assumir** que as variáveis de ambiente estão corretas
- **SEMPRE perguntar** DB_HOST, DB_PORT, DB_USER, DB_PWD na implementação
- **Variáveis mudam** quando RDS é recriado ou alterado
- Testar endpoints que precisam do banco vs endpoints que não precisam

### **2. IAM Role Correto para Troubleshooting**
- Usar `role-acesso-ssm` em vez de `ecsInstanceRole`
- Permite acesso via SSM Session Manager para debugging
- Essencial para troubleshooting em produção

### **3. Verificar AZs do ALB**
- Sempre verificar em quais AZs o ALB está configurado
- Criar instâncias EC2 APENAS nas AZs do ALB
- Evita problemas de targets unhealthy

### **4. Configuração de Rede Três Camadas**
- ALB (público) → EC2 (privado) → RDS (privado)
- Security Groups referenciam outros Security Groups
- Permite flexibilidade e segurança

---

## ✅ VALIDAÇÃO FINAL

### **Testes Realizados:**
```bash
# Health Check
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/api/versao
# Resultado: "Bia 4.2.0" ✅

# Teste de Banco
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/api/usuarios
# Resultado: JSON com dados do banco ✅

# Aplicação Web
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/
# Resultado: Frontend React funcionando ✅
```

### **Status dos Serviços:**
- ✅ ALB: Active e respondendo
- ✅ Target Group: 2 targets healthy
- ✅ ECS Service: 2 tasks running
- ✅ RDS: Conectividade funcionando
- ✅ Aplicação: Frontend + Backend + Banco integrados

---

**DESAFIO-3 CONCLUÍDO COM SUCESSO! 🎉**