# 🎯 ESTRUTURA COMPLETA - DESAFIOS FUNDAMENTAIS BIA

## 📋 **VISÃO GERAL DOS DESAFIOS**

### **🔄 DESAFIOS FUNDAMENTAIS - CRONOLOGIA COMPLETA**
**Objetivo:** Implementar todos os desafios fundamentais da BIA em sequência cronológica

**Baseado em anotações reais e implementações testadas**

---

## 📅 **DIA 1 - PARTE 6: PREPARAÇÃO DA VM**

### **🎯 Objetivos do Dia 1 - Parte 6:**
1. ✅ **Criar VM** usando Ubuntu 24.04
2. ✅ **Instalar ferramentas** de desenvolvimento
3. ✅ **Configurar ambiente** de trabalho

### **🔧 Implementação Dia 1 - Parte 6:**

**1. Criar VM Ubuntu 24.04:**
```bash
# Lançar instância EC2 com Ubuntu 24.04
aws ec2 run-instances \
  --image-id ami-02f3f602d23f1659d \
  --instance-type t3.micro \
  --key-name KEY-RSA-PEM-LINUX-BIA \
  --security-group-ids sg-bia-dev \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-dev}]'
```

**2. Configurar Ambiente:**
```bash
# Criar pasta de trabalho
mkdir -p ~/formacaoaws
cd ~/formacaoaws

# Clonar projeto BIA (baseado em suas anotações)
git clone https://github.com/henrylle/bia
cd bia

# Subir serviço local para desenvolvimento
docker compose up -d

# Verificar funcionamento
curl http://localhost:3001/api/versao
```

---

## 📅 **DIA 1 - PARTE 7: MÁQUINA BIA-DEV**

### **🎯 Objetivos do Dia 1 - Parte 7:**
1. ✅ **Lançar máquina bia-dev** (Rodar a BIA na sua VM)
2. ✅ **Configurar permissões IAM** para o usuário ao invés da role
3. ✅ **Testar comunicação com o ECR**

### **🔧 Implementação Dia 1 - Parte 7:**

**1. Criar Security Group bia-dev (baseado em suas anotações):**
```bash
# Criar Security Group para bia-dev
aws ec2 create-security-group \
  --group-name "bia-dev" \
  --description "Security group acesso para o mundo" \
  --vpc-id ${VPC_ID}

# Autorizar SSH
aws ec2 authorize-security-group-ingress \
  --group-id sg-bia-dev \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Autorizar HTTP
aws ec2 authorize-security-group-ingress \
  --group-id sg-bia-dev \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

**2. Lançar instância bia-dev:**
```bash
aws ec2 run-instances \
  --image-id ami-02f3f602d23f1659d \
  --instance-type t3.micro \
  --key-name KEY-RSA-PEM-LINUX-BIA \
  --security-group-ids sg-bia-dev \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-dev}]'
```

**3. Configurar ECR (baseado em suas anotações):**
```bash
# Criar repositório ECR
aws ecr create-repository --repository-name bia

# Login no ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 557772028142.dkr.ecr.us-east-1.amazonaws.com
```

---

## 📅 **DIA 2: BUILD E PUSH**

### **🎯 Objetivos do Dia 2:**
1. ✅ **Fazer build da sua VM**
2. ✅ **Fazer push para o ECR da sua VM**

### **🔧 Implementação Dia 2 (baseado em suas anotações):**

**1. Configurações de Banco RDS:**
```bash
# Variáveis de ambiente (suas credenciais)
export DB_USER=postgres
export DB_PWD=GjIPOyL4vcuf5h1VHmeh
export DB_HOST=database-1.ctcq4u628ebj.us-east-1.rds.amazonaws.com
export DB_PORT=5432
```

**2. Build e Deploy Local:**
```bash
cd ~/formacaoaws/bia

# Recriar container com novas configurações (suas anotações)
docker compose down -v
docker compose build server
docker compose up -d

# Criar banco e executar migrations (suas anotações)
docker compose exec server bash -c 'npx sequelize db:create'
docker compose exec server bash -c 'npx sequelize db:migrate'
```

**3. Build e Push para ECR (suas anotações):**
```bash
# Build da aplicação BIA
docker build -t bia:latest .

# Tag para ECR (seu registry)
docker tag bia:latest 557772028142.dkr.ecr.us-east-1.amazonaws.com/bia:latest

# Push para ECR
docker push 557772028142.dkr.ecr.us-east-1.amazonaws.com/bia:latest
```

---

## 📅 **DIA 3 - PARTE 5: SITE ESTÁTICO S3 ✅ CONCLUÍDO**

### **🎯 Objetivos do Dia 3 - Parte 5:**
1. ✅ **Criar bucket S3** para servir site da BIA estaticamente
2. ✅ **Script shell** para gerar assets do React da BIA
3. ✅ **API por argumento** (endereço passado por parâmetro)
4. ✅ **Sync com S3** (diretório local → bucket)
5. ✅ **Integração com Dia 2** (usar API como backend)
6. ✅ **Registro em banco** (dados persistidos via API)

### **🔧 Implementação Dia 3 - Parte 5:**
**✅ IMPLEMENTADO 100% - Ver documentação completa:**
- **DESAFIO-S3-SITE-ESTATICO.md** - Implementação detalhada
- **Scripts criados:** deploys3.sh, reacts3.sh, s3.sh
- **Site funcionando:** React hospedado no S3
- **Integração:** Site S3 → API → RDS
- **Endpoint API:** http://bia-549844302.us-east-1.elb.amazonaws.com

---

## 📅 **DIA 4 - PARTE 6: PORTEIRO (BASTION HOST)**

### **🎯 Objetivos do Dia 4 - Parte 6:**
1. ✅ **Script para lançar porteiro** na zona b (subnet default)
2. ✅ **Script para túnel RDS** na porta local 5433
3. ✅ **Comunicação com banco** e inserir 1 registro manualmente
4. ✅ **Túnel para BIA** na porta 3002 para ver registro
5. ✅ **Script para máquina porteiro**

### **🔧 Implementação Dia 4 - Parte 6 (baseado em suas anotações):**

**1. Criar Security Groups (suas configurações):**
```bash
# Security Group para Porteiro
aws ec2 create-security-group \
  --group-name "porteiro-sg" \
  --description "Security group para bastion host porteiro" \
  --vpc-id ${VPC_ID}

# Autorizar SSH
aws ec2 authorize-security-group-ingress \
  --group-id sg-porteiro \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

**2. Script para Lançar Porteiro:**
```bash
#!/bin/bash
# launch-porteiro.sh
echo "🚀 Lançando máquina porteiro na zona b..."

aws ec2 run-instances \
  --image-id ami-02f3f602d23f1659d \
  --instance-type t3.micro \
  --key-name KEY-RSA-PEM-BASTION \
  --security-group-ids sg-porteiro \
  --subnet-id subnet-zona-b \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=porteiro}]' \
  --user-data '#!/bin/bash
    apt update
    apt install -y postgresql-client
    apt install -y curl'

echo "✅ Porteiro lançado na zona b"
```

**3. Túneis SSH (baseado em suas anotações reais):**
```bash
#!/bin/bash
# tunnel-rds.sh
PORTEIRO_IP="ec2-34-204-47-140.compute-1.amazonaws.com"
RDS_ENDPOINT="database-1.ctcq4u628ebj.us-east-1.rds.amazonaws.com"

echo "🔗 Criando túnel SSH para RDS na porta 5433..."

# Túnel para RDS (baseado em suas anotações)
ssh -f -N -i "KEY-RSA-PEM-BASTION.pem" -L 5433:${RDS_ENDPOINT}:5432 ec2-user@${PORTEIRO_IP}

echo "✅ Túnel RDS ativo na porta 5433"
echo "💡 Para conectar: psql -h localhost -p 5433 -U postgres -d bia"
```

**4. Túnel para BIA (suas anotações):**
```bash
#!/bin/bash
# tunnel-bia.sh
PORTEIRO_IP="ec2-34-204-47-140.compute-1.amazonaws.com"
ALB_ENDPOINT="bia-549844302.us-east-1.elb.amazonaws.com"

echo "🔗 Criando túnel SSH para BIA na porta 3002..."

# Túnel para BIA (baseado em suas anotações)
ssh -f -N -i "KEY-RSA-PEM-BASTION.pem" -L 3002:${ALB_ENDPOINT}:80 ec2-user@${PORTEIRO_IP}

echo "✅ Túnel BIA ativo na porta 3002"
echo "💡 Acesse: http://localhost:3002"
```

**5. Inserir Registro no Banco (suas credenciais):**
```bash
#!/bin/bash
# insert-record.sh
echo "📝 Inserindo registro no banco via túnel..."

# Usando credenciais das suas anotações
PGPASSWORD=GjIPOyL4vcuf5h1VHmeh psql -h localhost -p 5433 -U postgres -d bia -c "
INSERT INTO usuarios (nome, email, created_at) 
VALUES ('Usuario Porteiro', 'teste@porteiro.com', NOW());
"

echo "✅ Registro inserido com sucesso"
```

**6. Conectividade via SSM (suas anotações integradas):**
```bash
# Conectar via SSM (sem chave)
aws ssm start-session --target i-054666af8593890b9 --profile bia-serverless

# Túnel via SSM para RDS (suas anotações)
aws ssm start-session \
  --target i-0481fd856099d1d54 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["database-1.ctcq4u628ebj.us-east-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5433"]}' \
  --profile bia-serverless

# Conectar via EC2 Instance Connect (chaves temporárias)
aws ec2-instance-connect ssh --instance-id i-018081087fbbca57b --profile bia-serverless
```

### **🔐 Configurações de Segurança (suas anotações):**

**IAM Policies necessárias (suas policies):**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
                "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSessionToRemoteHost",
                "arn:aws:ec2:us-east-1:*:instance/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2-instance-connect:SendSSHPublicKey",
                "ec2-instance-connect:OpenTunnel"
            ],
            "Resource": "arn:aws:ec2:us-east-1:*:*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        }
    ]
}
```

---

## 🔗 **INTEGRAÇÃO ENTRE DESAFIOS**

### **📊 Fluxo Cronológico Completo:**
```
DIA 1 - PARTE 6: VM Ubuntu + Ferramentas + git clone bia
    ↓
DIA 1 - PARTE 7: VM bia-dev + IAM + ECR (557772028142.dkr.ecr.us-east-1.amazonaws.com)
    ↓
DIA 2: Build + Push ECR + RDS (database-1.ctcq4u628ebj.us-east-1.rds.amazonaws.com)
    ↓
DIA 3 - PARTE 5: Site Estático S3 → API (bia-549844302.us-east-1.elb.amazonaws.com) ✅ CONCLUÍDO
    ↓
DIA 4 - PARTE 6: Porteiro + Túneis SSH + SSM
```

### **🏗️ Arquitetura Final Completa (com suas configurações):**
```
┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   VM bia-dev    │    │   ECR Registry   │    │   Site S3        │
│   (Dia 1)       │    │   (Dia 2)        │    │   (Dia 3)        │
│                 │    │                  │    │                  │
│ • git clone bia │───▶│ • 557772028142   │───▶│ • React build    │
│ • docker compose│    │ • bia:latest     │    │ • VITE_API_URL   │
│ • KEY-RSA-PEM   │    │ • Push/Pull      │    │ • Static hosting │
└─────────────────┘    └─────────────────┘    └──────────────────┘
                                                        │
        ┌──────────────────┐                           ▼
        │   Porteiro       │                  ┌──────────────────┐
        │   (Dia 4)        │                  │   ALB + ECS      │
        │                  │                  │   (API Backend)  │
        │ • SSH Tunnels    │◀─────────────────│                  │
        │ • RDS :5433      │                  │ • bia-549844302  │
        │ • BIA :3002      │                  │ • Container ECR  │
        │ • SSM + VPC      │                  │ • Load Balancer  │
        └──────────────────┘                  └──────────────────┘
                                                        │
                                                        ▼
                                               ┌──────────────────┐
                                               │   RDS Database   │
                                               │   (PostgreSQL)   │
                                               │                  │
                                               │ • database-1     │
                                               │ • ctcq4u628ebj   │
                                               │ • GjIPOyL4vcuf5h │
                                               └──────────────────┘
```

---

## 📊 **COMANDOS ÚTEIS (SUAS ANOTAÇÕES INTEGRADAS)**

### **Listar instâncias (suas queries):**
```bash
# Listar instâncias com detalhes (sua query)
aws ec2 describe-instances \
    --filters Name=tag-key,Values=* \
    --query 'Reservations[*].Instances[*].{VpcId:VpcId,ID_Instancia:InstanceId,Tipo:InstanceType,Estado:State.Name,IpPublico:PublicIpAddress,AZ:Placement.AvailabilityZone,Nome:Tags[?Key==`Name`]|[0].Value}' \
    --output table

# Listar apenas IDs das instâncias bia-dev (sua query)
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId]' \
    --filters 'Name=tag-value,Values=bia-dev' \
    --output text

# Formato limpo (sua query)
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PrivateIpAddress,PublicIpAddress,Tags[?Key==`Name`].Value[]]' --output json | tr -d '\n[] "' | perl -pe 's/i-/\ni-/g' | tr ',' '\t' | sed -e 's/null/None/g' | grep '^i-' | column -t
```

### **Gerenciar Security Groups (suas configurações):**
```bash
# Listar Security Groups (sua query)
aws ec2 describe-security-groups \
    --query 'SecurityGroups[*].{Groupname:GroupName,GroupID:GroupId,VpcID:VpcId}' \
    --output table

# Autorizar acesso entre Security Groups (suas regras)
aws ec2 authorize-security-group-ingress \
    --group-id sg-bia-dev \
    --protocol tcp \
    --port 22 \
    --source-group sg-porteiro
```

### **Conectividade Avançada (suas anotações):**
```bash
# Chaves temporárias (seu método)
ssh-keygen -t rsa -f chave1
aws ec2-instance-connect send-ssh-public-key \
    --instance-id i-0e9341dc2d748b8f3 \
    --instance-os-user ec2-user \
    --ssh-public-key file://chave1.pub \
    --profile bia-serverless
ssh -o "IdentitiesOnly=yes" -i chave1 ec2-user@44.195.89.199

# Túnel misto SSH + SSM (sua configuração)
aws ssm start-session \
    --target i-0481fd856099d1d54 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["30.0.8.136"],"portNumber":["22"],"localPortNumber":["2250"]}' \
    --profile bia-serverless
```

---

## 📋 **STATUS DOS DESAFIOS**

### **✅ CONCLUÍDOS:**
- **DIA 3 - PARTE 5 (Site S3):** 100% implementado e documentado

### **📝 DOCUMENTADOS COM SUAS ANOTAÇÕES:**
- **DIA 1 - PARTE 6:** VM Ubuntu + git clone + docker compose
- **DIA 1 - PARTE 7:** bia-dev + Security Groups + ECR
- **DIA 2:** Build + Push + RDS + Migrations
- **DIA 4 - PARTE 6:** Porteiro + SSH Tunnels + SSM + VPC Endpoints

### **🔧 CONFIGURAÇÕES REAIS INTEGRADAS:**
- **ECR:** 557772028142.dkr.ecr.us-east-1.amazonaws.com/bia:latest
- **RDS:** database-1.ctcq4u628ebj.us-east-1.rds.amazonaws.com
- **ALB:** bia-549844302.us-east-1.elb.amazonaws.com
- **Keys:** KEY-RSA-PEM-LINUX-BIA, KEY-RSA-PEM-BASTION
- **Security Groups:** bia-dev, porteiro-sg, endpoint-sg

---

## 📚 **DOCUMENTAÇÃO RELACIONADA**

- **DESAFIO-S3-SITE-ESTATICO.md** - Implementação completa do Dia 3 - Parte 5
- **historico-conversas-amazonq.md** - Histórico de todas as implementações
- **Suas anotações** - Comandos reais testados e funcionais

---

*Documentação criada em: 07/11/2025*  
*Contexto: Estrutura cronológica completa dos Desafios Fundamentais BIA*  
*Baseado em: Anotações reais e implementações testadas*  
*Status: Dia 3 - Parte 5 (S3) concluído, demais dias documentados com configurações reais*
