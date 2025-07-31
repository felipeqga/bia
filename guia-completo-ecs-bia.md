# Guia Completo - Infraestrutura ECS BIA

## 📋 **Visão Geral**

Este guia permite recriar completamente a infraestrutura ECS do projeto BIA, incluindo:
- RDS PostgreSQL
- ECR Repository
- ECS Cluster com instâncias EC2
- Task Definition
- ECS Service
- Scripts de deploy

---

## 🎯 **Pré-requisitos**

### **Recursos AWS Necessários:**
- ✅ VPC configurada (vpc-08b8e37ee6ff01860)
- ✅ Subnets públicas:
  - us-east-1a: subnet-068e3484d05611445
  - us-east-1b: subnet-0c665b052ff5c528d
- ✅ Security Groups configurados:
  - `bia-db` (sg-0d954919e73c1af79)
  - `bia-web` (sg-001cbdec26830c553)
  - `bia-dev` (sg-0ba2485fb94124c9f)

### **Ferramentas Necessárias:**
- AWS CLI configurado
- Docker instalado
- Node.js 22+ instalado
- Git configurado

---

## 🗄️ **PASSO 1: Configurar RDS PostgreSQL**

### **1.1 Criar RDS Instance**
```bash
aws rds create-db-instance \
  --db-instance-identifier bia \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 17.4 \
  --master-username postgres \
  --master-user-password Kgegwlaj6mAIxzHaEqgo \
  --allocated-storage 20 \
  --storage-type gp2 \
  --vpc-security-group-ids sg-0d954919e73c1af79 \
  --availability-zone us-east-1a \
  --no-publicly-accessible \
  --backup-retention-period 0 \
  --no-performance-insights-enabled \
  --region us-east-1
```

### **1.2 Aguardar RDS Ficar Disponível**
```bash
aws rds wait db-instance-available --db-instance-identifier bia --region us-east-1
```

### **1.3 Criar Database**
```bash
docker run --rm postgres:16.1 psql "postgresql://postgres:Kgegwlaj6mAIxzHaEqgo@bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432/postgres" -c "CREATE DATABASE bia;"
```

### **1.4 Executar Migrations**
```bash
cd /home/ec2-user/bia
npm install
DB_HOST=bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com \
DB_PWD=Kgegwlaj6mAIxzHaEqgo \
DB_USER=postgres \
DB_PORT=5432 \
npx sequelize db:migrate
```

---

## 🐳 **PASSO 2: Configurar ECR Repository**

### **2.1 Criar Repository**
```bash
aws ecr create-repository \
  --repository-name bia \
  --image-tag-mutability MUTABLE \
  --encryption-configuration encryptionType=AES256 \
  --region us-east-1
```

### **2.2 Configurar Scripts**

**Criar build.sh:**
```bash
cat > /home/ec2-user/bia/build.sh << 'EOF'
ECR_REGISTRY="387678648422.dkr.ecr.us-east-1.amazonaws.com"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
docker build -t bia .
docker tag bia:latest $ECR_REGISTRY/bia:latest
docker push $ECR_REGISTRY/bia:latest
EOF

chmod +x /home/ec2-user/bia/build.sh
```

**Criar deploy.sh:**
```bash
cat > /home/ec2-user/bia/deploy.sh << 'EOF'
./build.sh
aws ecs update-service --cluster cluster-bia --service service-bia --force-new-deployment --region us-east-1
EOF

chmod +x /home/ec2-user/bia/deploy.sh
```

---

## 🚀 **PASSO 3: Criar ECS Cluster**

### **3.1 Criar Cluster via Console AWS**
**⚠️ Importante:** O cluster deve ser criado via Console AWS devido à complexidade do Auto Scaling Group.

**Configurações:**
- **Nome:** `cluster-bia`
- **Infrastructure:** Amazon EC2 instances
- **Instance Type:** t3.micro
- **Desired Capacity:** Min=1, Max=1
- **Subnets:** us-east-1a, us-east-1b
- **Security Group:** bia-web

### **3.2 Verificar Cluster**
```bash
aws ecs describe-clusters --clusters cluster-bia --region us-east-1
```

---

## 📋 **PASSO 4: Criar Task Definition**

### **4.1 Corrigir Dockerfile**
```bash
# Obter IP público da instância ECS
INSTANCE_ID=$(aws ecs describe-container-instances \
  --cluster cluster-bia \
  --container-instances $(aws ecs list-container-instances \
    --cluster cluster-bia \
    --query 'containerInstanceArns[0]' \
    --output text) \
  --query 'containerInstances[0].ec2InstanceId' \
  --output text \
  --region us-east-1)

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region us-east-1)

# Atualizar Dockerfile
sed -i "s|VITE_API_URL=http://.*|VITE_API_URL=http://$PUBLIC_IP|" /home/ec2-user/bia/Dockerfile
```

### **4.2 Criar Task Definition**
```bash
aws ecs register-task-definition \
  --family task-def-bia \
  --network-mode bridge \
  --requires-compatibilities EC2 \
  --container-definitions '[
    {
      "name": "bia",
      "image": "387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest",
      "cpu": 1024,
      "memory": 3072,
      "memoryReservation": 409,
      "essential": true,
      "portMappings": [
        {
          "name": "porta-80",
          "containerPort": 8080,
          "hostPort": 80,
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "environment": [
        {"name": "DB_USER", "value": "postgres"},
        {"name": "DB_PWD", "value": "Kgegwlaj6mAIxzHaEqgo"},
        {"name": "DB_HOST", "value": "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"},
        {"name": "DB_PORT", "value": "5432"}
      ]
    }
  ]' \
  --region us-east-1
```

---

## 🔄 **PASSO 5: Criar ECS Service**

### **5.1 Criar Service**
```bash
aws ecs create-service \
  --cluster cluster-bia \
  --service-name service-bia \
  --task-definition task-def-bia:1 \
  --desired-count 1 \
  --launch-type EC2 \
  --scheduling-strategy REPLICA \
  --deployment-configuration '{
    "minimumHealthyPercent": 0,
    "maximumPercent": 100,
    "deploymentCircuitBreaker": {
      "enable": false,
      "rollback": false
    }
  }' \
  --region us-east-1
```

### **5.2 Aguardar Service Estabilizar**
```bash
aws ecs wait services-stable --cluster cluster-bia --services service-bia --region us-east-1
```

---

## 🌐 **PASSO 6: Build e Deploy Inicial**

### **6.1 Fazer Build e Push da Imagem**
```bash
cd /home/ec2-user/bia
./build.sh
```

### **6.2 Forçar Deployment**
```bash
aws ecs update-service \
  --cluster cluster-bia \
  --service service-bia \
  --force-new-deployment \
  --region us-east-1
```

### **6.3 Aguardar Deployment**
```bash
aws ecs wait services-stable --cluster cluster-bia --services service-bia --region us-east-1
```

---

## ✅ **PASSO 7: Validação**

### **7.1 Obter IP Público**
```bash
INSTANCE_ID=$(aws ecs describe-container-instances \
  --cluster cluster-bia \
  --container-instances $(aws ecs list-container-instances \
    --cluster cluster-bia \
    --query 'containerInstanceArns[0]' \
    --output text) \
  --query 'containerInstances[0].ec2InstanceId' \
  --output text \
  --region us-east-1)

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region us-east-1)

echo "IP Público da aplicação: $PUBLIC_IP"
```

### **7.2 Testar Aplicação**
```bash
# Testar API
curl http://$PUBLIC_IP/api/versao

# Testar frontend (deve retornar HTML)
curl -s http://$PUBLIC_IP | head -10
```

### **7.3 Verificar Database**
```bash
docker run --rm postgres:16.1 psql \
  "postgresql://postgres:Kgegwlaj6mAIxzHaEqgo@bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com:5432/bia" \
  -c "\dt"
```

---

## 🔧 **Comandos de Troubleshooting**

### **Verificar Status dos Recursos**
```bash
# RDS
aws rds describe-db-instances --db-instance-identifier bia --region us-east-1

# ECR
aws ecr describe-repositories --repository-names bia --region us-east-1
aws ecr describe-images --repository-name bia --region us-east-1

# ECS Cluster
aws ecs describe-clusters --clusters cluster-bia --region us-east-1

# ECS Service
aws ecs describe-services --cluster cluster-bia --services service-bia --region us-east-1

# Tasks
aws ecs list-tasks --cluster cluster-bia --region us-east-1
aws ecs describe-tasks --cluster cluster-bia --tasks $(aws ecs list-tasks --cluster cluster-bia --query 'taskArns[0]' --output text) --region us-east-1
```

### **Logs e Debug**
```bash
# Logs da task (via CloudWatch)
aws logs describe-log-groups --log-group-name-prefix /ecs/task-def-bia --region us-east-1

# Conectar na instância ECS (se SSM configurado)
aws ssm start-session --target $INSTANCE_ID --region us-east-1

# Verificar containers Docker na instância
docker ps -a
docker logs CONTAINER_ID
```

### **Redeployment**
```bash
# Forçar novo deployment
cd /home/ec2-user/bia
./deploy.sh

# Ou manualmente
aws ecs update-service --cluster cluster-bia --service service-bia --force-new-deployment --region us-east-1
```

---

## 📊 **Configurações Importantes**

### **Security Groups**
- **bia-db:** Permite PostgreSQL (5432) de bia-web e bia-dev
- **bia-web:** Permite HTTP (80) público
- **bia-dev:** Para desenvolvimento/debug

### **Deployment Configuration**
- **Minimum Healthy Percent:** 0% (permite parar task antiga)
- **Maximum Percent:** 100% (máximo 1 task por vez)
- **Strategy:** ROLLING
- **Circuit Breaker:** Desabilitado

### **Environment Variables**
- **DB_HOST:** Endpoint do RDS
- **DB_USER:** postgres
- **DB_PWD:** Senha do RDS
- **DB_PORT:** 5432

### **Port Mapping**
- **Host Port:** 80 (público)
- **Container Port:** 8080 (aplicação)
- **Protocol:** TCP/HTTP

---

## 🎉 **Resultado Final**

Após seguir todos os passos, você terá:

- ✅ **RDS PostgreSQL** funcionando com migrations aplicadas
- ✅ **ECR Repository** com imagem da aplicação
- ✅ **ECS Cluster** com instância EC2 t3.micro
- ✅ **Task Definition** configurada corretamente
- ✅ **ECS Service** rodando com deployment otimizado
- ✅ **Scripts** de build e deploy funcionais
- ✅ **Aplicação BIA** acessível via HTTP público

**URLs de acesso:**
- **Aplicação:** `http://IP_PUBLICO`
- **API:** `http://IP_PUBLICO/api/versao`

---

*Criado em: 31/07/2025 19:00 UTC*
*Baseado na configuração real do projeto BIA*
