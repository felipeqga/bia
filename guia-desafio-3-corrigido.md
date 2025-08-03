# 🎯 GUIA DESAFIO-3 CORRIGIDO - ECS Cluster com ALB

## 📋 **MÉTODO CORRETO PARA CRIAR CLUSTER ECS**

**Data:** 03/08/2025  
**Status:** ✅ TESTADO E VALIDADO  
**Baseado em:** Demonstração prática bem-sucedida  

---

## 🎯 **OBJETIVO:**
Criar cluster ECS com Application Load Balancer para alta disponibilidade da aplicação BIA.

---

## 📊 **PARÂMETROS CONFIRMADOS:**

```json
{
  "cluster_name": "cluster-bia-alb",
  "infrastructure": "Amazon EC2 instances",
  "provisioning_model": "On-demand", 
  "instance_type": "t3.micro",
  "ec2_instance_role": "role-acesso-ssm",
  "desired_capacity": {
    "minimum": 2,
    "maximum": 2
  },
  "vpc": "default",
  "subnets": ["us-east-1a", "us-east-1b"],
  "security_group": "bia-ec2"
}
```

---

## 🚀 **PASSO-A-PASSO CORRETO:**

### **PASSO 1: Verificar Pré-requisitos ✅**

**Security Groups (já existem):**
- `bia-alb` - HTTP/HTTPS público
- `bia-ec2` - All TCP do bia-alb  
- `bia-db` - PostgreSQL do bia-ec2

**Application Load Balancer (já existe):**
- Nome: `bia`
- DNS: `bia-1260066125.us-east-1.elb.amazonaws.com`
- Target Group: `tg-bia` (health check: `/api/versao`)

**RDS (já existe):**
- Host: `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com`
- Credenciais: postgres/Kgegwlaj6mAIxzHaEqgo

### **PASSO 2: Criar Cluster ECS via Console AWS 🔄**

**⚠️ IMPORTANTE:** Use APENAS o Console AWS, NÃO o CLI!

**Configurações no Console:**
1. **AWS Console** → **ECS** → **Clusters** → **Create Cluster**
2. **Cluster name:** `cluster-bia-alb`
3. **Infrastructure:** `Amazon EC2 instances`
4. **Provisioning model:** `On-demand`
5. **Instance type:** `t3.micro`
6. **EC2 instance role:** `role-acesso-ssm`
7. **Desired capacity:** Minimum=2, Maximum=2
8. **VPC:** default
9. **Subnets:** us-east-1a, us-east-1b
10. **Security group:** bia-ec2

**Resultado esperado:**
- ✅ Cluster criado: `cluster-bia-alb`
- ✅ Auto Scaling Group criado automaticamente
- ✅ Launch Template criado automaticamente
- ✅ CloudFormation Stack criado automaticamente
- ✅ 2 Instâncias EC2 criadas automaticamente
- ✅ Instâncias registradas no cluster automaticamente

### **PASSO 3: Criar Task Definition 🔄**

```bash
# Criar Log Group
aws logs create-log-group --log-group-name /ecs/task-def-bia-alb

# Registrar Task Definition
aws ecs register-task-definition --cli-input-json '{
  "family": "task-def-bia-alb",
  "networkMode": "bridge",
  "requiresCompatibilities": ["EC2"],
  "containerDefinitions": [
    {
      "name": "bia",
      "image": "387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest",
      "cpu": 1024,
      "memory": 3072,
      "memoryReservation": 409,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 0,
          "protocol": "tcp",
          "name": "porta-aleatoria",
          "appProtocol": "http"
        }
      ],
      "environment": [
        {"name": "DB_HOST", "value": "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"},
        {"name": "DB_PORT", "value": "5432"},
        {"name": "DB_USER", "value": "postgres"},
        {"name": "DB_PWD", "value": "Kgegwlaj6mAIxzHaEqgo"},
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
    }
  ]
}'
```

### **PASSO 4: Criar ECS Service 🔄**

```bash
aws ecs create-service \
  --cluster cluster-bia-alb \
  --service-name service-bia-alb \
  --task-definition task-def-bia-alb \
  --desired-count 2 \
  --launch-type EC2 \
  --deployment-configuration maximumPercent=200,minimumHealthyPercent=50 \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/0108bc8d0bf7b11e,containerName=bia,containerPort=8080 \
  --role arn:aws:iam::387678648422:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS \
  --placement-strategy type=spread,field=attribute:ecs.availability-zone
```

### **PASSO 5: Atualizar Dockerfile com DNS do ALB 🔄**

```dockerfile
# Usar DNS do ALB em vez de IP fixo
RUN cd client && VITE_API_URL=http://bia-1260066125.us-east-1.elb.amazonaws.com npm run build
```

### **PASSO 6: Validação Final 🔄**

```bash
# Testar health check
curl http://bia-1260066125.us-east-1.elb.amazonaws.com/api/versao

# Testar conectividade com banco
curl http://bia-1260066125.us-east-1.elb.amazonaws.com/api/usuarios

# Verificar Target Group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/0108bc8d0bf7b11e
```

---

## 🔍 **COMANDOS DE VERIFICAÇÃO:**

### **Status do Cluster:**
```bash
aws ecs describe-clusters --clusters cluster-bia-alb
```

### **Instâncias Registradas:**
```bash
aws ecs list-container-instances --cluster cluster-bia-alb
```

### **Auto Scaling Group:**
```bash
aws autoscaling describe-auto-scaling-groups
```

### **CloudFormation Stack:**
```bash
aws cloudformation describe-stacks --stack-name Infra-ECS-Cluster-cluster-bia-alb-*
```

---

## ⚠️ **DIFERENÇAS CRÍTICAS:**

| **Aspecto** | **Método Errado (CLI)** | **Método Correto (Console)** |
|-------------|-------------------------|------------------------------|
| **Comando** | `aws ecs create-cluster` | Console AWS wizard |
| **Resultado** | Cluster vazio | Cluster + infraestrutura completa |
| **Instâncias** | 0 | 2 automáticas |
| **ASG** | Não criado | Criado automaticamente |
| **Capacity Provider** | Vazio | Criado automaticamente |

---

## 🏆 **RESULTADO ESPERADO:**

**✅ Cluster ECS funcional com:**
- 2 instâncias EC2 t3.micro
- Auto Scaling Group (Min=2, Max=2)
- Launch Template com AMI ECS otimizada
- CloudFormation Stack gerenciando tudo
- Capacity Provider para EC2
- Instâncias registradas automaticamente

**✅ Aplicação BIA acessível via:**
- ALB: `http://bia-1260066125.us-east-1.elb.amazonaws.com`
- Health check: `/api/versao` → "Bia 4.2.0"
- API: `/api/usuarios` → JSON com dados do banco

---

*Guia baseado em demonstração prática bem-sucedida*  
*Testado e validado em: 03/08/2025*  
*Método Console AWS confirmado como único que funciona*