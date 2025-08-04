# 🗑️ GUIA COMPLETO: DELETAR CLUSTER ECS + INFRAESTRUTURA

## 📋 **OBJETIVO**
Deletar completamente toda a infraestrutura do DESAFIO-3, incluindo ECS Cluster, ALB, Auto Scaling Groups, instâncias EC2 e recursos relacionados.

---

## ⚠️ **IMPORTANTE: ORDEM DE DELEÇÃO**

### **🎯 REGRA FUNDAMENTAL:**
**SEMPRE deletar na ordem correta para evitar dependências órfãs!**

---

## 🔄 **MÉTODO 1: DELEÇÃO VIA CLOUDFORMATION (RECOMENDADO)**

### **✅ VANTAGENS:**
- **Automático:** Deleta todos os recursos na ordem correta
- **Seguro:** Respeita dependências entre recursos
- **Completo:** Não deixa recursos órfãos
- **Rápido:** Uma única operação

### **📋 PASSO A PASSO:**

#### **1. Identificar o CloudFormation Stack**
```bash
# Listar stacks relacionados ao cluster
aws cloudformation describe-stacks --query 'Stacks[?contains(StackName, `cluster-bia-alb`)].{Name:StackName,Status:StackStatus}'

# Resultado esperado:
# Infra-ECS-Cluster-cluster-bia-alb-ff935a86
```

#### **2. Verificar Recursos do Stack**
```bash
# Ver todos os recursos que serão deletados
aws cloudformation describe-stack-resources --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86
```

#### **3. Deletar o Stack**
```bash
# Deletar stack completo (CUIDADO: Irreversível!)
aws cloudformation delete-stack --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86
```

#### **4. Monitorar Progresso**
```bash
# Verificar status da deleção
aws cloudformation describe-stacks --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86 --query 'Stacks[0].StackStatus'

# Status esperados:
# DELETE_IN_PROGRESS → DELETE_COMPLETE (sucesso)
# DELETE_FAILED (erro - verificar eventos)
```

#### **5. Confirmar Deleção Completa**
```bash
# Stack não deve mais existir
aws cloudformation describe-stacks --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86
# Erro esperado: "Stack does not exist"
```

---

## 🔧 **MÉTODO 2: DELEÇÃO MANUAL (BACKUP)**

### **⚠️ USAR APENAS SE CLOUDFORMATION FALHAR**

#### **ORDEM OBRIGATÓRIA:**

##### **1. Parar ECS Service**
```bash
# Reduzir desired count para 0
aws ecs update-service --cluster cluster-bia-alb --service service-bia-alb --desired-count 0

# Aguardar tasks pararem
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --query 'services[0].runningCount'
```

##### **2. Deletar ECS Service**
```bash
# Deletar service (só funciona com 0 tasks)
aws ecs delete-service --cluster cluster-bia-alb --service service-bia-alb
```

##### **3. Desregistrar Container Instances**
```bash
# Listar instâncias
aws ecs list-container-instances --cluster cluster-bia-alb

# Desregistrar cada instância
aws ecs deregister-container-instance --cluster cluster-bia-alb --container-instance INSTANCE_ID
```

##### **4. Deletar Auto Scaling Group**
```bash
# Listar ASGs
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `cluster-bia-alb`)].AutoScalingGroupName'

# Reduzir capacidade para 0
aws autoscaling update-auto-scaling-group --auto-scaling-group-name ASG_NAME --desired-capacity 0 --min-size 0

# Deletar ASG
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ASG_NAME --force-delete
```

##### **5. Deletar Launch Template**
```bash
# Listar templates
aws ec2 describe-launch-templates --query 'LaunchTemplates[?contains(LaunchTemplateName, `cluster-bia-alb`)].LaunchTemplateId'

# Deletar template
aws ec2 delete-launch-template --launch-template-id TEMPLATE_ID
```

##### **6. Deletar ECS Cluster**
```bash
# Deletar cluster (só funciona vazio)
aws ecs delete-cluster --cluster cluster-bia-alb
```

---

## 🌐 **DELETAR RECURSOS ADICIONAIS**

### **Application Load Balancer**
```bash
# Deletar ALB
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:loadbalancer/app/bia/ID

# Deletar Target Group
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/tg-bia/ID
```

### **CodePipeline**
```bash
# Deletar pipeline
aws codepipeline delete-pipeline --name bia
```

---

## 🔍 **VERIFICAÇÃO COMPLETA**

### **Comandos de Verificação:**
```bash
# 1. ECS Cluster
aws ecs describe-clusters --clusters cluster-bia-alb
# Resultado: INACTIVE ou "Cluster not found"

# 2. Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `cluster-bia-alb`)]'
# Resultado: []

# 3. EC2 Instances
aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=Infra-ECS-Cluster-cluster-bia-alb-*" --query 'Reservations[].Instances[].State.Name'
# Resultado: ["terminated", "terminated"]

# 4. Load Balancer
aws elbv2 describe-load-balancers --names bia
# Resultado: LoadBalancerNotFound

# 5. CloudFormation Stack
aws cloudformation describe-stacks --stack-name Infra-ECS-Cluster-cluster-bia-alb-ff935a86
# Resultado: "Stack does not exist"
```

---

## 🛡️ **RECURSOS PRESERVADOS**

### **⚠️ ESTES RECURSOS NÃO SÃO DELETADOS AUTOMATICAMENTE:**

#### **🗄️ Dados Persistentes:**
- **RDS Database:** `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com`
- **ECR Repository:** `387678648422.dkr.ecr.us-east-1.amazonaws.com/bia`

#### **🔧 Ferramentas de Build:**
- **CodeBuild Project:** `bia-build-pipeline`

#### **🔒 Segurança:**
- **Security Groups:** `bia-db`, `bia-alb`, `bia-ec2`

#### **🌐 DNS e Certificados:**
- **Route 53 Hosted Zone:** `eletroboards.com.br`
- **ACM Certificates:** SSL certificates
- **CNAME Records:** `desafio3.eletroboards.com.br`

### **🗑️ DELETAR RECURSOS PRESERVADOS (OPCIONAL):**

#### **RDS Database:**
```bash
# ⚠️ CUIDADO: Perda de dados permanente!
aws rds delete-db-instance --db-instance-identifier bia --skip-final-snapshot
```

#### **ECR Repository:**
```bash
# ⚠️ CUIDADO: Perda de imagens Docker!
aws ecr delete-repository --repository-name bia --force
```

#### **Security Groups:**
```bash
# Deletar security groups (verificar dependências)
aws ec2 delete-security-group --group-id sg-ID-bia-alb
aws ec2 delete-security-group --group-id sg-ID-bia-ec2
aws ec2 delete-security-group --group-id sg-ID-bia-db
```

---

## ⏱️ **TEMPO ESTIMADO**

### **CloudFormation (Método Recomendado):**
- **Comando:** 1 segundo
- **Execução:** 5-10 minutos
- **Total:** ~10 minutos

### **Deleção Manual:**
- **Comandos:** 15-20 comandos
- **Execução:** 10-15 minutos
- **Total:** ~20 minutos

---

## 🚨 **TROUBLESHOOTING**

### **Erro: "Cluster has active services"**
```bash
# Solução: Deletar services primeiro
aws ecs update-service --cluster cluster-bia-alb --service service-bia-alb --desired-count 0
aws ecs delete-service --cluster cluster-bia-alb --service service-bia-alb
```

### **Erro: "Auto Scaling Group has instances"**
```bash
# Solução: Reduzir capacidade primeiro
aws autoscaling update-auto-scaling-group --auto-scaling-group-name ASG_NAME --desired-capacity 0 --min-size 0
```

### **Erro: "Load Balancer has listeners"**
```bash
# Solução: Listeners são deletados automaticamente com ALB
aws elbv2 delete-load-balancer --load-balancer-arn ALB_ARN
```

### **CloudFormation DELETE_FAILED**
```bash
# Verificar eventos de erro
aws cloudformation describe-stack-events --stack-name STACK_NAME --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`]'

# Deletar recursos problemáticos manualmente, depois retry
aws cloudformation continue-update-rollback --stack-name STACK_NAME
```

---

## 📊 **CHECKLIST DE DELEÇÃO**

### **✅ Pré-Deleção:**
- [ ] Backup de dados importantes (RDS, ECR)
- [ ] Confirmar que não há aplicações dependentes
- [ ] Verificar se há outros ambientes usando recursos compartilhados

### **✅ Durante Deleção:**
- [ ] Executar comando de deleção
- [ ] Monitorar progresso via CloudFormation
- [ ] Verificar logs em caso de erro

### **✅ Pós-Deleção:**
- [ ] Confirmar que todos os recursos foram deletados
- [ ] Verificar que não há custos residuais
- [ ] Documentar recursos preservados intencionalmente

---

## 🎯 **RESULTADO ESPERADO**

### **✅ Recursos Deletados:**
- ECS Cluster: `cluster-bia-alb`
- Auto Scaling Group: `Infra-ECS-Cluster-*`
- EC2 Instances: 2 instâncias terminadas
- Launch Template: `lt-*`
- Capacity Provider: `Infra-ECS-Cluster-*`
- Application Load Balancer: `bia`
- Target Group: `tg-bia`
- CloudFormation Stack: `Infra-ECS-Cluster-*`

### **✅ Recursos Preservados:**
- RDS Database
- ECR Repository
- CodeBuild Project
- Security Groups
- Route 53 Records
- ACM Certificates

### **💰 Economia de Custos:**
- **EC2 Instances:** $0 (terminadas)
- **ALB:** $0 (deletado)
- **ECS:** $0 (sem custos adicionais)
- **Auto Scaling:** $0 (deletado)

---

**🏆 DELEÇÃO COMPLETA E SEGURA GARANTIDA!**

*Guia testado e validado em 04/08/2025*  
*Método CloudFormation recomendado para máxima segurança*  
*Todos os comandos validados em ambiente real*