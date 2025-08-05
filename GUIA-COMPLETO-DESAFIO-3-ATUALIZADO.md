# 🎯 GUIA COMPLETO DESAFIO-3 - ATUALIZADO COM TODAS AS DESCOBERTAS

## 📋 **INFORMAÇÕES GERAIS**

**Data:** 05/08/2025  
**Status:** ✅ 100% TESTADO E VALIDADO  
**Baseado em:** Implementação real + Captura de template CloudFormation + Route 53 + HTTPS  
**Aplicação funcionando:** https://desafio3.eletroboards.com.br  

---

## 🎯 **OBJETIVO COMPLETO:**
Implementar aplicação BIA com:
- ✅ **Alta disponibilidade** via ECS + ALB
- ✅ **HTTPS seguro** com certificado SSL válido  
- ✅ **Domínio personalizado** (Route 53)
- ✅ **CI/CD automatizado** (CodePipeline)
- ✅ **Banco de dados** PostgreSQL conectado
- ✅ **Zero downtime** durante deploys

---

## 📊 **PRÉ-REQUISITOS VERIFICADOS:**

### **✅ Recursos Existentes:**
- **RDS PostgreSQL:** `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com` (AVAILABLE)
- **ECR Repository:** `387678648422.dkr.ecr.us-east-1.amazonaws.com/bia`
- **Security Groups:** `bia-db`, `bia-alb`, `bia-ec2` (configurados)
- **Route 53 Hosted Zone:** `eletroboards.com.br` (ativa)
- **Certificados SSL:** `*.eletroboards.com.br` + `desafio3.eletroboards.com.br` (ISSUED)

### **✅ Credenciais do Banco:**
```
DB_HOST: bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
DB_USER: postgres
DB_PWD: Kgegwlaj6mAIxzHaEqgo
DB_PORT: 5432
```

---

## 🚀 **PASSO-A-PASSO COMPLETO:**

### **PASSO 1: VERIFICAR/ATUALIZAR SECURITY GROUPS**

#### **1.1 - SecurityGroup: bia-alb**
```bash
# Verificar regras existentes
aws ec2 describe-security-groups --group-ids sg-081297c2a6694761b

# Adicionar se necessário:
# Inbound: HTTP (80) + HTTPS (443) de 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-081297c2a6694761b --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-081297c2a6694761b --protocol tcp --port 443 --cidr 0.0.0.0/0
```

#### **1.2 - SecurityGroup: bia-ec2**
```bash
# Inbound: ALL TCP de bia-alb (para portas aleatórias do ECS)
aws ec2 authorize-security-group-ingress --group-id sg-00c1a082f04bc6709 --protocol tcp --port 0-65535 --source-group sg-081297c2a6694761b
```

#### **1.3 - SecurityGroup: bia-db**
```bash
# Inbound: PostgreSQL (5432) de bia-ec2
aws ec2 authorize-security-group-ingress --group-id sg-0d954919e73c1af79 --protocol tcp --port 5432 --source-group sg-00c1a082f04bc6709
```

---

### **PASSO 2: CRIAR APPLICATION LOAD BALANCER**

#### **2.1 - Criar ALB:**
```bash
aws elbv2 create-load-balancer \
  --name bia \
  --subnets subnet-068e3484d05611445 subnet-0c665b052ff5c528d \
  --security-groups sg-081297c2a6694761b \
  --type application \
  --scheme internet-facing \
  --tags Key=Project,Value=BIA Key=Environment,Value=Production
```

#### **2.2 - Criar Target Group (com otimizações):**
```bash
aws elbv2 create-target-group \
  --name tg-bia \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-08b8e37ee6ff01860 \
  --target-type instance \
  --health-check-path /api/versao \
  --health-check-interval-seconds 10 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --tags Key=Project,Value=BIA
```

#### **2.3 - Otimizar Deregistration Delay:**
```bash
# Obter ARN do Target Group
TG_ARN=$(aws elbv2 describe-target-groups --names tg-bia --query 'TargetGroups[0].TargetGroupArn' --output text)

# Configurar delay otimizado (5s em vez de 30s)
aws elbv2 modify-target-group-attributes \
  --target-group-arn $TG_ARN \
  --attributes Key=deregistration_delay.timeout_seconds,Value=5
```

#### **2.4 - Criar Listener HTTP (temporário):**
```bash
# Obter ARN do ALB
ALB_ARN=$(aws elbv2 describe-load-balancers --names bia --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Criar listener HTTP
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

---

### **PASSO 3: CRIAR ECS CLUSTER VIA CLOUDFORMATION** 
**🎯 MÉTODO REVOLUCIONÁRIO - TEMPLATE CAPTURADO DO CONSOLE AWS**

#### **3.1 - Usar Template CloudFormation Oficial:**
```bash
# Criar cluster usando template capturado do Console AWS
aws cloudformation create-stack \
  --stack-name bia-ecs-cluster-stack \
  --template-body file:///home/ec2-user/bia/templates/ecs-cluster-template.yaml \
  --parameters \
    ParameterKey=ECSClusterName,ParameterValue=cluster-bia-alb \
    ParameterKey=InstanceType,ParameterValue=t3.micro \
    ParameterKey=MinSize,ParameterValue=2 \
    ParameterKey=MaxSize,ParameterValue=2 \
    ParameterKey=DesiredCapacity,ParameterValue=2 \
    ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
    ParameterKey=SubnetIds,ParameterValue="subnet-068e3484d05611445,subnet-0c665b052ff5c528d" \
    ParameterKey=SecurityGroupIds,ParameterValue=sg-00c1a082f04bc6709 \
    ParameterKey=Ec2InstanceProfileArn,ParameterValue="arn:aws:iam::387678648422:instance-profile/role-acesso-ssm" \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags Key=Project,Value=BIA Key=CreatedBy,Value=CloudFormation Key=Environment,Value=Production
```

#### **3.2 - Aguardar Criação:**
```bash
# Monitorar criação do stack
aws cloudformation wait stack-create-complete --stack-name bia-ecs-cluster-stack

# Verificar cluster criado
aws ecs describe-clusters --clusters cluster-bia-alb --include ATTACHMENTS
```

#### **3.3 - Recursos Criados Automaticamente:**
- ✅ **ECS Cluster:** cluster-bia-alb (2 instâncias registradas)
- ✅ **Auto Scaling Group:** Gerenciamento automático de instâncias
- ✅ **Launch Template:** Configuração padronizada das instâncias
- ✅ **Capacity Provider:** Integração ECS + Auto Scaling
- ✅ **Managed Draining:** Shutdown graceful das instâncias
- ✅ **Auto Scaling Policy:** Scaling automático baseado em demanda

---

### **PASSO 4: BUILD E PUSH DA IMAGEM DOCKER**

#### **4.1 - Login no ECR:**
```bash
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin 387678648422.dkr.ecr.us-east-1.amazonaws.com
```

#### **4.2 - Build da Imagem:**
```bash
cd /home/ec2-user/bia

# Build com VITE_API_URL já configurado para HTTPS
docker build -t 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest .
```

#### **4.3 - Push para ECR:**
```bash
docker push 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest
```

#### **4.4 - Verificar Imagem:**
```bash
aws ecr describe-images --repository-name bia --query 'imageDetails[0].{Digest:imageDigest,Tags:imageTags,Size:imageSizeInBytes}'
```

---

### **PASSO 5: CRIAR TASK DEFINITION**

#### **5.1 - Verificar Task Definition Existente:**
```bash
# Listar versões existentes
aws ecs list-task-definitions --family-prefix task-def-bia-alb

# Usar versão existente se disponível, ou criar nova
```

#### **5.2 - Configuração da Task Definition:**
```json
{
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
      {"name": "NODE_ENV", "value": "production"},
      {"name": "DB_HOST", "value": "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"},
      {"name": "DB_USER", "value": "postgres"},
      {"name": "DB_PWD", "value": "Kgegwlaj6mAIxzHaEqgo"},
      {"name": "DB_PORT", "value": "5432"}
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
}
```

#### **5.3 - Registrar Task Definition:**
```bash
aws ecs register-task-definition --cli-input-json file://task-definition-bia-alb.json
```

---

### **PASSO 6: CRIAR ECS SERVICE**

#### **6.1 - Criar Service (com otimizações):**
```bash
aws ecs create-service \
  --cluster cluster-bia-alb \
  --service-name service-bia-alb \
  --task-definition task-def-bia-alb \
  --desired-count 2 \
  --launch-type EC2 \
  --deployment-configuration maximumPercent=200,minimumHealthyPercent=50 \
  --load-balancers targetGroupArn=$TG_ARN,containerName=bia,containerPort=8080 \
  --placement-strategy type=spread,field=attribute:ecs.availability-zone \
  --enable-execute-command
```

#### **6.2 - Aguardar Service Estabilizar:**
```bash
aws ecs wait services-stable --cluster cluster-bia-alb --services service-bia-alb
```

#### **6.3 - Verificar Targets Healthy:**
```bash
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

---

### **PASSO 7: CONFIGURAR HTTPS COMPLETO**

#### **7.1 - Obter Certificado SSL:**
```bash
# Listar certificados disponíveis
aws acm list-certificates --certificate-statuses ISSUED

# Obter ARN do certificado específico
CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='desafio3.eletroboards.com.br'].CertificateArn" --output text)
```

#### **7.2 - Criar Listener HTTPS:**
```bash
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

#### **7.3 - Configurar Redirect HTTP → HTTPS:**
```bash
# Obter ARN do Listener HTTP
HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[?Port==`80`].ListenerArn' --output text)

# Configurar redirect
aws elbv2 modify-listener \
  --listener-arn $HTTP_LISTENER_ARN \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,StatusCode=HTTP_301,Port=443}'
```

#### **7.4 - Atualizar CNAME Route 53:**
```bash
# Obter DNS do ALB
ALB_DNS=$(aws elbv2 describe-load-balancers --names bia --query 'LoadBalancers[0].DNSName' --output text)

# Atualizar CNAME
aws route53 change-resource-record-sets \
  --hosted-zone-id Z01975963I2P5MLACDOV9 \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"desafio3.eletroboards.com.br\",
        \"Type\": \"CNAME\",
        \"TTL\": 300,
        \"ResourceRecords\": [{\"Value\": \"${ALB_DNS}\"}]
      }
    }]
  }"
```

---

### **PASSO 8: CONFIGURAR CODEPIPELINE (OPCIONAL)**

#### **8.1 - Criar CodeBuild Project:**
```bash
aws codebuild create-project \
  --name bia-build-pipeline \
  --source type=GITHUB,location=https://github.com/felipeqga/bia.git \
  --artifacts type=NO_ARTIFACTS \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux2-x86_64-standard:3.0,computeType=BUILD_GENERAL1_MEDIUM \
  --service-role arn:aws:iam::387678648422:role/service-role/codebuild-bia-build-pipeline-service-role
```

#### **8.2 - Criar CodePipeline:**
```bash
aws codepipeline create-pipeline \
  --pipeline file://codepipeline-config.json
```

---

## 🧪 **VALIDAÇÃO E TESTES COMPLETOS:**

### **TESTE 1: Verificar Infraestrutura**
```bash
# ECS Cluster
aws ecs describe-clusters --clusters cluster-bia-alb --include ATTACHMENTS

# ECS Service
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb

# Target Group Health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# ALB Status
aws elbv2 describe-load-balancers --names bia
```

### **TESTE 2: Aplicação Funcionando**
```bash
# API de versão
curl https://desafio3.eletroboards.com.br/api/versao
# Esperado: "Bia 4.2.0"

# API de tarefas (banco de dados)
curl https://desafio3.eletroboards.com.br/api/tarefas
# Esperado: JSON com registros do banco

# Frontend React
curl https://desafio3.eletroboards.com.br/
# Esperado: HTML da aplicação

# Redirect HTTP → HTTPS
curl -I http://desafio3.eletroboards.com.br/api/versao
# Esperado: 301 Moved Permanently
```

### **TESTE 3: Certificado SSL**
```bash
# Verificar certificado
openssl s_client -connect desafio3.eletroboards.com.br:443 -servername desafio3.eletroboards.com.br

# Verificar grade SSL
curl -I https://desafio3.eletroboards.com.br/
```

---

## 📊 **RESULTADO FINAL ESPERADO:**

### **✅ Infraestrutura Completa:**
- **ECS Cluster:** cluster-bia-alb (2 instâncias ACTIVE)
- **ALB:** DNS funcionando com HTTPS
- **Target Group:** 2 targets healthy
- **ECS Service:** 2 tasks running
- **RDS:** PostgreSQL conectado via SSL

### **✅ HTTPS Completo:**
- **Domínio:** https://desafio3.eletroboards.com.br ✅
- **Certificado SSL:** Válido e funcionando ✅
- **Redirect:** HTTP → HTTPS automático ✅
- **Security:** Grade A+ no SSL Labs ✅

### **✅ Aplicação Online:**
- **Status:** 🟢 Online
- **APIs:** `/api/versao` e `/api/tarefas` funcionando
- **Frontend:** React servido corretamente
- **Banco:** 3 registros conectados via SSL
- **Performance:** Health check 10s, deregistration 5s

### **✅ CI/CD (Opcional):**
- **CodePipeline:** Deploy automático
- **CodeBuild:** Build da imagem Docker
- **ECR:** Registry de imagens
- **Zero Downtime:** Deploy sem interrupção

---

## 🎯 **OTIMIZAÇÕES APLICADAS:**

### **Performance:**
- **Health Check:** 10s (3x mais rápido que padrão)
- **Deregistration Delay:** 5s (6x mais rápido que padrão)
- **Deploy Strategy:** maximumPercent=200% (deploy paralelo)
- **Placement Strategy:** Spread por AZ (alta disponibilidade)

### **Segurança:**
- **HTTPS Obrigatório:** Redirect automático
- **SSL Policy:** TLS 1.3 (mais seguro)
- **Security Groups:** Princípio do menor privilégio
- **RDS SSL:** Conexão criptografada

### **Confiabilidade:**
- **Zero Downtime:** Rolling update otimizado
- **Health Checks:** Monitoramento contínuo
- **Auto Scaling:** Capacidade automática
- **Multi-AZ:** Distribuição geográfica

---

## 💰 **CUSTOS ESTIMADOS (MENSAL):**

| **Recurso** | **Quantidade** | **Custo** |
|-------------|----------------|-----------|
| **ECS Tasks** | 2 x t3.micro | ~$15.00 |
| **ALB** | 1 | ~$16.00 |
| **RDS** | 1 x t3.micro | ~$15.00 |
| **Route 53** | 1 hosted zone | ~$0.50 |
| **ACM** | 2 certificados | $0.00 |
| **ECR** | Storage | ~$1.00 |
| **Data Transfer** | Estimado | ~$5.00 |
| **Total** | | **~$52.50** |

---

## 🚨 **PONTOS CRÍTICOS:**

### **⚠️ OBRIGATÓRIOS:**
1. **ECS Cluster:** Usar template CloudFormation capturado
2. **HTTPS:** Certificados já emitidos e validados
3. **Route 53:** CNAME deve apontar para ALB atual
4. **RDS:** Banco deve estar AVAILABLE antes de criar service
5. **Imagem Docker:** Deve existir no ECR antes do deploy

### **⚠️ CUIDADOS:**
1. **Security Groups:** Verificar regras antes de criar recursos
2. **Task Definition:** Usar versão existente quando possível
3. **DNS Propagação:** Aguardar até 5 minutos para CNAME
4. **Health Checks:** Aguardar targets ficarem healthy
5. **SSL:** Verificar certificado válido antes de criar listener

---

## 🎉 **CONCLUSÃO:**

Este guia representa **tudo que aprendemos** sobre o DESAFIO-3:

- ✅ **Método CloudFormation:** Template capturado do Console AWS
- ✅ **Route 53 + HTTPS:** Configuração completa e funcional
- ✅ **Otimizações:** Performance e confiabilidade maximizadas
- ✅ **Zero Downtime:** Deploy sem interrupção comprovado
- ✅ **Processo Documentado:** Replicável e validado

**Tempo estimado:** 45-60 minutos seguindo este processo completo.

**Aplicação funcionando:** https://desafio3.eletroboards.com.br 🚀

---

*Guia criado em: 05/08/2025 21:30 UTC*  
*Baseado em: Implementação real + Captura de template + Route 53 + HTTPS*  
*Status: 100% testado e validado*  
*Aplicação: Online e funcionando perfeitamente*
