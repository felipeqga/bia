# Guia Completo: Criação de EC2 com Aplicação BIA do Zero

## 📋 **Pré-requisitos e Dependências**

### **Infraestrutura AWS Necessária:**
- ✅ VPC configurada
- ✅ Subnet pública na zona us-east-1a
- ✅ Security Group `bia-dev` com regras:
  - Inbound: SSH (22), HTTP (80), portas customizadas (3001, 3008)
  - Outbound: All traffic
- ✅ Role IAM `role-acesso-ssm` com 8 políticas obrigatórias

### **Role IAM - Configuração Crítica:**
**Nome:** `role-acesso-ssm`

**Trust Policy (quem pode assumir a role):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**Permission Policies (o que a role pode fazer):**
1. `AmazonSSMManagedInstanceCore` (AWS Managed)
2. `AmazonSSMPatchAssociation` (AWS Managed)
3. `CloudWatchAgentServerPolicy` (AWS Managed)
4. `AmazonEC2ReadOnlyAccess` (AWS Managed)
5. `AmazonS3ReadOnlyAccess` (AWS Managed)
6. `SecretsManagerReadWrite` (AWS Managed)
7. `AmazonEC2ContainerRegistryReadOnly` (AWS Managed)
8. **Policy customizada para PassRole:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ec2:RunInstances",
      "iam:PassRole"
    ],
    "Resource": [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:iam::ACCOUNT-ID:role/role-acesso-ssm"
    ],
    "Condition": {
      "StringEquals": {
        "iam:PassedToService": "ec2.amazonaws.com"
      }
    }
  }]
}
```

---

## 🚀 **Processo Completo de Criação**

### **1. Criação da EC2**
```bash
# Executar script do projeto BIA
cd /home/ec2-user/bia/scripts
./lancar_ec2_zona_a.sh
```

**Especificações da EC2:**
- **Tipo:** t3.micro
- **AMI:** Amazon Linux 2023
- **Storage:** 15GB GP2
- **Role IAM:** role-acesso-ssm
- **Security Group:** bia-dev
- **User Data:** Instala Docker, Node.js 22, UV automaticamente

### **2. Aguardar Inicialização**
```bash
# Aguardar 2-3 minutos para user data terminar
# Verificar se EC2 está running e com IP público
aws ec2 describe-instances --instance-ids INSTANCE-ID
```

### **3. Configurar Security Group**
```bash
# Liberar porta da aplicação (exemplo: 3008)
aws ec2 authorize-security-group-ingress \
  --group-id sg-XXXXXXXX \
  --protocol tcp \
  --port 3008 \
  --cidr 0.0.0.0/0
```

### **4. Conectar via SSM e Configurar Aplicação**
```bash
# Conectar na nova EC2
cd /home/ec2-user/bia/scripts
./start-session-bash.sh INSTANCE-ID

# OU usar SSM send-command para automação
aws ssm send-command --instance-ids INSTANCE-ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["COMANDO"]'
```

### **5. Clonar Projeto BIA**
```bash
cd /home/ec2-user
git clone https://github.com/henrylle/bia.git
chown -R ec2-user:ec2-user bia
```

### **6. Criar Dockerfile Customizado**
```dockerfile
FROM public.ecr.aws/docker/library/node:22-slim
RUN npm install -g npm@11 --loglevel=error
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --loglevel=error
COPY client/package*.json ./client/
RUN cd client && npm install --legacy-peer-deps --loglevel=error
COPY . .
# CRÍTICO: Usar IP público da EC2, não localhost
RUN cd client && VITE_API_URL=http://IP-PUBLICO:PORTA npm run build
RUN cd client && npm prune --production && rm -rf node_modules/.cache
EXPOSE 8080
CMD [ "npm", "start" ]
```

### **7. Criar Docker Compose Customizado**
```yaml
services:
  database:
    image: postgres:16.1
    container_name: database-PORTA
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bia
    ports:
      - "PORTA-EXTERNA:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  server:
    build:
      context: .
      dockerfile: Dockerfile.PORTA
    container_name: bia-PORTA
    ports:
      - "PORTA:8080"
    depends_on:
      - database
    environment:
      - NODE_ENV=production
      - DB_HOST=database
      - DB_PORT=5432
      - DB_USER=postgres
      - DB_PWD=postgres

volumes:
  postgres_data:
```

### **8. Subir Aplicação**
```bash
cd /home/ec2-user/bia
docker compose -f compose-PORTA.yml up -d --build
```

### **9. Executar Migration (CRÍTICO)**
```bash
# Aguardar containers subirem (30-60 segundos)
docker compose -f compose-PORTA.yml exec server bash -c 'npx sequelize db:migrate'
```

### **10. Testar Aplicação**
```bash
# Testar API
curl http://IP-PUBLICO:PORTA/api/versao

# Testar no navegador
http://IP-PUBLICO:PORTA
```

---

## ⚠️ **Principais Dificuldades e Soluções**

### **1. Problema: Permissão iam:PassRole**
**Erro:** `You are not authorized to perform: iam:PassRole`
**Causa:** Role não tinha permissão para se passar para novas EC2s
**Solução:** Adicionar policy customizada com `iam:PassRole` específica

### **2. Problema: Migration não executava**
**Erro:** `connect ECONNREFUSED 127.0.0.1:5433`
**Causa:** Container da aplicação não conseguia conectar no PostgreSQL
**Soluções tentadas:**
- ❌ Containers isolados sem rede
- ❌ Configuração hardcoded para localhost
- ✅ **Solução final:** Docker Compose com variáveis de ambiente corretas

### **3. Problema: Frontend não carregava**
**Erro:** API calls falhando
**Causa:** `VITE_API_URL=http://localhost:PORTA` no build
**Solução:** Usar IP público da EC2 no build do Vite

### **4. Problema: Conectividade entre containers**
**Erro:** Containers não se comunicavam
**Causa:** Falta de rede Docker ou configuração incorreta
**Solução:** Docker Compose com `depends_on` e variáveis de ambiente

---

## 🎯 **Checklist de Validação**

### **✅ Antes de criar EC2:**
- [ ] Role `role-acesso-ssm` existe com 8 políticas
- [ ] Security Group `bia-dev` configurado
- [ ] VPC e Subnet disponíveis

### **✅ Após criar EC2:**
- [ ] EC2 está running
- [ ] IP público atribuído
- [ ] SSM funcionando
- [ ] User data executado (Docker, Node.js instalados)

### **✅ Após configurar aplicação:**
- [ ] Containers rodando (`docker ps`)
- [ ] API respondendo (`/api/versao`)
- [ ] Migration executada (tabelas criadas)
- [ ] Frontend carregando no navegador
- [ ] Dados persistindo no banco

---

## 📝 **Comandos de Troubleshooting**

```bash
# Verificar containers
docker ps -a

# Verificar logs
docker logs CONTAINER-NAME

# Verificar rede
docker network ls

# Testar conectividade do banco
docker exec CONTAINER-NAME psql -U postgres -d bia -c "\dt"

# Verificar migration
docker exec CONTAINER-NAME psql -U postgres -d bia -c "SELECT * FROM \"SequelizeMeta\";"

# Reconectar via SSM
aws ssm start-session --target INSTANCE-ID
```

---

## 🎉 **Resultado Final**

**Com este processo você terá:**
- ✅ EC2 funcionando com aplicação BIA
- ✅ PostgreSQL com dados persistentes
- ✅ Frontend configurado corretamente
- ✅ API funcionando
- ✅ Migrations aplicadas
- ✅ Acesso via SSM

**URLs de acesso:**
- **Aplicação:** `http://IP-PUBLICO:PORTA`
- **API:** `http://IP-PUBLICO:PORTA/api/versao`

---

*Guia criado baseado na experiência real de criação de duas EC2s com aplicação BIA funcionando independentemente.*
