# 🎯 DESAFIO-3: ECS Cluster com ALB - Contexto Técnico

## 📋 **INFORMAÇÕES TÉCNICAS VALIDADAS**

**Data:** 04/08/2025  
**Status:** ✅ IMPLEMENTADO E TESTADO  
**Método:** Console AWS + CLI híbrido  

---

## 🏗️ **ARQUITETURA IMPLEMENTADA:**

```
Internet → ALB → Target Group → ECS Service → 2 Tasks → 2 EC2 Instances
                                     ↓
                              RDS PostgreSQL
```

### **Componentes:**
- **Application Load Balancer:** Distribuição de tráfego
- **Target Group:** Health check `/api/versao`
- **ECS Cluster:** 2 instâncias t3.micro
- **ECS Service:** 2 tasks com rolling update
- **RDS:** PostgreSQL preservado

---

## 🔧 **RECURSOS CRIADOS AUTOMATICAMENTE PELO CONSOLE:**

### **CloudFormation Stack:** `Infra-ECS-Cluster-cluster-bia-alb-ff935a86`

| **Recurso** | **Tipo** | **Nome Gerado** |
|-------------|----------|-----------------|
| **ECS Cluster** | `AWS::ECS::Cluster` | `cluster-bia-alb` |
| **Launch Template** | `AWS::EC2::LaunchTemplate` | `ECSLaunchTemplate_nvur8v7N80kw` |
| **Auto Scaling Group** | `AWS::AutoScaling::AutoScalingGroup` | `Infra-ECS-Cluster-cluster-bia-alb-ff935a86-ECSAutoScalingGroup-9M7Xbjhx2eZa` |
| **Capacity Provider** | `AWS::ECS::CapacityProvider` | `Infra-ECS-Cluster-cluster-bia-alb-ff935a86-AsgCapacityProvider-HolxEs1g0dj6` |
| **CP Association** | `AWS::ECS::ClusterCapacityProviderAssociations` | `cluster-bia-alb` |

### **Configurações Automáticas:**
- **User Data:** `echo ECS_CLUSTER=cluster-bia-alb >> /etc/ecs/ecs.config`
- **Auto Scaling Policy:** `ECSManagedAutoScalingPolicy-af501c31-21b7-4efe-85a9-a9c446bae310`
- **Managed Draining:** `ecs-managed-draining-termination-hook`
- **Security Group:** `bia-ec2` aplicado automaticamente
- **IAM Role:** `role-acesso-ssm` aplicado automaticamente

---

## 📊 **INSTÂNCIAS EC2 CRIADAS:**

| **Instance ID** | **AZ** | **IP Privado** | **Status** |
|-----------------|--------|----------------|------------|
| `i-05048f5d8fa335cae` | us-east-1b | 172.31.90.98 | ✅ InService |
| `i-0796b07e5a9a96015` | us-east-1a | 172.31.5.60 | ✅ InService |

### **Configurações das Instâncias:**
- **AMI:** `ami-07985a96d172b21ee` (ECS Optimized)
- **Instance Type:** t3.micro
- **Security Group:** `sg-00c1a082f04bc6709` (bia-ec2)
- **IAM Role:** `role-acesso-ssm`
- **Subnets:** subnet-068e3484d05611445 (1a), subnet-0c665b052ff5c528d (1b)

---

## 🔗 **RECURSOS CRIADOS VIA CLI:**

### **Application Load Balancer:**
- **Nome:** `bia`
- **DNS:** `bia-560867504.us-east-1.elb.amazonaws.com`
- **ARN:** `arn:aws:elasticloadbalancing:us-east-1:387678648422:loadbalancer/app/bia/373e7ae4e5a96d88`
- **Security Group:** `sg-081297c2a6694761b` (bia-alb)

### **Target Group:**
- **Nome:** `tg-bia`
- **ARN:** `arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/f49273d7c410536f`
- **Health Check:** `/api/versao` (HTTP 200)
- **Port:** 80

### **Task Definition:**
- **Family:** `task-def-bia-alb`
- **Revision:** 16
- **Network Mode:** bridge
- **CPU:** 1024, **Memory:** 3072
- **Container Port:** 8080 (dynamic host port)

### **ECS Service:**
- **Nome:** `service-bia-alb`
- **Desired Count:** 2
- **Launch Type:** EC2
- **Placement Strategy:** spread by AZ
- **Deployment Config:** maxPercent=200, minHealthy=50

---

## 🎯 **OTIMIZAÇÕES APLICADAS:**

### **Target Group Otimizado:**
- **Health Check Interval:** 30s → 10s (3x mais rápido)
- **Deregistration Delay:** 30s → 5s (6x mais rápido)

### **ECS Service Otimizado:**
- **Maximum Percent:** 100% → 200% (deploy paralelo)
- **Rolling Update:** Zero downtime comprovado

### **Resultado:**
- **Deploy Time:** 7min 19s → 5min 2s
- **Melhoria:** 31% de redução no tempo de deploy

---

## 🔍 **COMANDOS DE VERIFICAÇÃO:**

### **Status do Cluster:**
```bash
# Verificar cluster
aws ecs describe-clusters --clusters cluster-bia-alb --include ATTACHMENTS

# Verificar instâncias registradas
aws ecs list-container-instances --cluster cluster-bia-alb

# Verificar service
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb
```

### **Status da Aplicação:**
```bash
# Testar aplicação
curl http://bia-560867504.us-east-1.elb.amazonaws.com/api/versao

# Verificar Target Group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/f49273d7c410536f
```

### **CloudFormation Stack:**
```bash
# Verificar stack
aws cloudformation describe-stacks --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86

# Verificar recursos do stack
aws cloudformation describe-stack-resources --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86
```

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Tasks não iniciam**
```bash
# Verificar eventos do service
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --query 'services[0].events[0:5]'

# Verificar recursos das instâncias
aws ecs describe-container-instances --cluster cluster-bia-alb
```

### **Problema: Target Group Unhealthy**
```bash
# Verificar health do target group
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/f49273d7c410536f

# Verificar logs da aplicação
aws logs describe-log-streams --log-group-name /ecs/task-def-bia-alb
```

---

## 📈 **MÉTRICAS DE SUCESSO:**

### **Zero Downtime Validado:**
- ✅ 58 verificações consecutivas com status 200 durante deploy
- ✅ Rolling update funcionando perfeitamente
- ✅ Health checks otimizados (10s interval)
- ✅ Deregistration delay otimizado (5s)

### **Performance:**
- ✅ Deploy 31% mais rápido
- ✅ 2 tasks distribuídas em 2 AZs
- ✅ Auto Scaling configurado
- ✅ Managed draining habilitado

---

## 🎯 **LIÇÕES APRENDIDAS:**

### **✅ O que funciona:**
1. **Console AWS** para criar cluster com instâncias EC2
2. **CLI** para criar ALB, Task Definition e Service
3. **Otimizações** via CLI após criação
4. **Monitoramento** contínuo durante implementação

### **❌ O que não funciona:**
1. Tentar replicar via CLI o que o Console faz
2. Criar recursos ECS individualmente
3. Ignorar as configurações automáticas do Console
4. Assumir que CLI pode fazer tudo

### **🔑 Descoberta Principal:**
**O Console AWS usa templates CloudFormation internos que não são públicos. Por isso certas operações SÓ podem ser feitas via Console!**

---

*Última atualização: 04/08/2025 01:00 UTC*  
*Status: IMPLEMENTADO E FUNCIONANDO*  
*Zero downtime comprovado: 58 verificações consecutivas*