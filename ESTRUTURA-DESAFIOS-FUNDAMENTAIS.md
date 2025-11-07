# 🎯 ESTRUTURA COMPLETA - DESAFIOS FUNDAMENTAIS BIA

## 📋 **VISÃO GERAL DOS DESAFIOS**

### **🔄 DESAFIOS FUNDAMENTAIS: DIA 2 - PARTE 7**

**Objetivo:** Fazer os desafios do dia 1 e 2 da BIA da sua VM

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
  --image-id ami-0e86e20dae90224e1 \  # Ubuntu 24.04 LTS
  --instance-type t3.medium \
  --key-name sua-key \
  --security-group-ids sg-xxxxxxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-dev-vm}]'
```

**2. Instalar Ferramentas:**
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# VS Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code -y

# DBeaver
wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo apt-key add -
echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
sudo apt update
sudo apt install dbeaver-ce -y

# Git
sudo apt install git -y

# Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# SAM CLI
wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
sudo ./sam-installation/install
```

**3. Configurar Ambiente:**
```bash
# Criar pasta de trabalho
mkdir -p ~/formacaoaws
cd ~/formacaoaws

# Configurar Git
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# Instalar extensão GitHub Pull Request no VS Code
code --install-extension GitHub.vscode-pull-request-github

# Autenticar no GitHub via VS Code
# (Fazer via interface do VS Code)
```

---

## 📅 **DIA 1 - PARTE 7: MÁQUINA BIA-DEV**

### **🎯 Objetivos do Dia 1 - Parte 7:**
1. ✅ **Lançar máquina bia-dev** (Rodar a BIA na sua VM)
2. ✅ **Configurar permissões IAM** para o usuário ao invés da role
3. ✅ **Testar comunicação com o ECR**

### **🔧 Implementação Dia 1 - Parte 7:**
```bash
# 1. Lançar instância EC2
aws ec2 run-instances \
  --image-id ami-xxxxxxxxx \
  --instance-type t3.micro \
  --key-name sua-key \
  --security-group-ids sg-xxxxxxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-dev}]'

# 2. Configurar usuário IAM (ao invés de role)
aws iam create-user --user-name bia-dev-user
aws iam attach-user-policy \
  --user-name bia-dev-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

# 3. Testar comunicação ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
```

---

## 📅 **DIA 2: BUILD E PUSH**

### **🎯 Objetivos do Dia 2:**
1. ✅ **Fazer build da sua VM**
2. ✅ **Fazer push para o ECR da sua VM**

### **🔧 Implementação Dia 2:**
```bash
# 1. Build da aplicação BIA
cd bia
docker build -t bia:latest .

# 2. Tag para ECR
docker tag bia:latest ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/bia:latest

# 3. Push para ECR
docker push ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/bia:latest
```

---

## 🌐 **DESAFIO S3: SITE ESTÁTICO (NOSSO FOCO)**

### **🎯 Objetivos do Desafio S3:**
1. ✅ **Criar bucket S3** para servir site da BIA estaticamente
2. ✅ **Script shell** para gerar assets do React
3. ✅ **API por argumento** (endereço passado por parâmetro)
4. ✅ **Sync com S3** (diretório local → bucket)
5. ✅ **Integração com Dia 2** (usar API como backend)
6. ✅ **Registro em banco** (dados persistidos via API)

---

## 🔗 **INTEGRAÇÃO ENTRE DESAFIOS**

### **📊 Fluxo Completo:**
```
DIA 1 - PARTE 6: VM Ubuntu + Ferramentas
    ↓
DIA 1 - PARTE 7: VM bia-dev + IAM + ECR
    ↓
DIA 2: Build + Push ECR
    ↓
DESAFIO S3: Site Estático → API (Dia 2) → RDS
```

### **🏗️ Arquitetura Final:**
```
┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   VM bia-dev    │    │   Site S3        │    │   API (Dia 2)    │
│   (Dia 1 + 2)   │    │   (Frontend)     │    │   ALB + ECS      │
│                 │    │                  │    │                  │
│ • Build local   │───▶│ • React build    │───▶│ • Container ECR  │
│ • Push ECR      │    │ • VITE_API_URL   │    │ • Backend API    │
│ • IAM User      │    │ • Static hosting │    │                  │
└─────────────────┘    └─────────────────┘    └──────────────────┘
                                                        │
                                                        ▼
                                               ┌──────────────────┐
                                               │   RDS Database   │
                                               │   (PostgreSQL)   │
                                               └──────────────────┘
```

---

## 📋 **STATUS DOS DESAFIOS**

### **✅ CONCLUÍDOS:**
- **DESAFIO S3:** 100% implementado e documentado
- **Integração:** Site S3 → API → RDS funcionando
- **Scripts:** Criados e testados
- **Troubleshooting:** Casos reais documentados

### **📝 PENDENTES (Para Referência):**
- **DIA 1 - PARTE 6:** VM Ubuntu + Ferramentas
- **DIA 1 - PARTE 7:** Lançar bia-dev + IAM User + ECR
- **DIA 2:** Build local + Push ECR

---

## 🎯 **PRÓXIMOS PASSOS SUGERIDOS**

### **Para Completar Todos os Desafios:**
1. **Implementar Dia 1 - Parte 6:** VM Ubuntu + Ferramentas
2. **Implementar Dia 1 - Parte 7:** VM bia-dev com IAM User
3. **Implementar Dia 2:** Build e Push local
4. **Integrar tudo:** VM → ECR → ECS → S3 → RDS

### **Benefícios da Implementação Completa:**
- ✅ **Ciclo completo:** Desenvolvimento → Build → Deploy → Frontend
- ✅ **Boas práticas:** IAM Users, ECR, S3, RDS
- ✅ **Arquitetura real:** Separação de responsabilidades
- ✅ **Experiência completa:** Todos os serviços AWS integrados

---

## 📚 **DOCUMENTAÇÃO RELACIONADA**

- **DESAFIO-S3-SITE-ESTATICO.md** - Implementação completa do site estático
- **historico-conversas-amazonq.md** - Histórico de todas as implementações
- **troubleshooting-*.md** - Soluções para problemas específicos

---

*Documentação criada em: 07/11/2025*  
*Contexto: Estrutura completa dos Desafios Fundamentais BIA*  
*Status: Desafio S3 concluído, Dias 1 e 2 documentados para referência*
