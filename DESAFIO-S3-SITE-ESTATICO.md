# 🌐 DESAFIO S3: SITE ESTÁTICO - DOCUMENTAÇÃO COMPLETA

## ⚠️ **OBSERVAÇÃO IMPORTANTE**
**O endpoint e IPs mencionados nesta documentação são temporários e específicos para este teste/desafio. Em implementações reais, você terá seus próprios endpoints e endereços IP conforme sua infraestrutura AWS.**

## 📋 **RESUMO DO DESAFIO**
Criar bucket S3, configurar hospedagem de site estático, aplicar permissões públicas e implementar scripts de deploy automatizado para aplicação React.

**Data de Implementação:** 07/11/2025  
**Status:** ✅ CONCLUÍDO COM SUCESSO  

---

## 📂 **PASSO 1: CLONAR PROJETO DO GITHUB**

### **🔧 Pré-requisito Obrigatório:**
```bash
# 1. Clonar o repositório do projeto BIA
git clone https://github.com/henrylle/bia.git

# 2. Entrar no diretório clonado
cd bia

# 3. Verificar estrutura
ls -la
# Deve mostrar: client/, scripts/, documentação, etc.

# 4. Instalar dependências do React
cd client
npm install
cd ..
```

### **🗂️ Estrutura Obrigatória Após Clone:**
```
/home/usuario/bia/           ← Diretório do projeto clonado
├── client/                  ← Aplicação React
│   ├── package.json         ← Dependências React
│   ├── src/                 ← Código fonte
│   ├── node_modules/        ← Criado após npm install
│   └── build/               ← Criado após npm run build
├── api/                     ← Backend Node.js
├── scripts/                 ← Scripts auxiliares
└── README.md                ← Documentação
```

---

## 📜 **PASSO 2: SCRIPTS NECESSÁRIOS**

### **Script 1: reacts3.sh**
```bash
#!/bin/bash
function build() {
    API_URL=$1
    echo $API_URL
    cd bia
    npm install
    echo " Iniciando build..."
    NODE_OPTIONS=--openssl-legacy-provider VITE_API_URL=$API_URL SKIP_PREFLIGHT_CHECK=true npm run build --prefix client
    echo " Build finalizado..."
    cd ..
}
```

### **Script 2: s3.sh**
```bash
#!/bin/bash
function envio_s3() {
    echo "Fazendo envio para o s3..."
    echo "Iniciando envio..."
    aws s3 sync ./client/build/ s3://SEU-BUCKET-NAME
    echo "Envio finalizado"
}
```

### **Script 3: deploys3.sh**
```bash
#!/bin/bash
AMBIENTE=$1
API_URL="http://SEU-ALB-OU-EC2-ENDPOINT"  # ← ALTERE AQUI
echo "Vou iniciar deploy no ambiente: $AMBIENTE"
echo "O endereco da api sera: $API_URL"

# Verificar ambiente válido
if [ "$AMBIENTE" != "hom" ] && [ "$AMBIENTE" != "prd" ]; then
    echo "Ambiente invalido"
    exit 1
fi

. reacts3.sh
. s3.sh

echo "Fazendo deploy..."

build $API_URL
envio_s3

echo "Finalizado"
```

### **🔧 Criar Scripts:**
```bash
# No diretório raiz do projeto bia
chmod +x reacts3.sh s3.sh deploys3.sh
```

---

## ☁️ **PASSO 3: CONFIGURAR AWS S3**

### **1. Criar Bucket S3**
```bash
# Usar timestamp para nome único
aws s3api create-bucket --bucket desafios-fundamentais-bia-$(date +%s)
```

### **2. Configurar Acesso Público**
```bash
# Remover bloqueio público
aws s3api delete-public-access-block --bucket SEU-BUCKET-NAME
```

### **3. Habilitar Website Estático**
```bash
aws s3api put-bucket-website \
  --bucket SEU-BUCKET-NAME \
  --website-configuration '{
    "IndexDocument":{"Suffix":"index.html"},
    "ErrorDocument":{"Key":"error.html"}
  }'
```

### **4. Aplicar Bucket Policy**
```bash
aws s3api put-bucket-policy --bucket SEU-BUCKET-NAME --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::SEU-BUCKET-NAME/*"]
    }
  ]
}'
```

---

## 🚀 **PASSO 4: EXECUTAR DEPLOY**

### **Comando de Deploy:**
```bash
# No diretório raiz do projeto bia
./deploys3.sh hom  # Para homologação
./deploys3.sh prd  # Para produção
```

### **🔍 Como Obter Endpoint:**
```bash
# Endpoint padrão S3 (us-east-1)
echo "http://SEU-BUCKET-NAME.s3-website-us-east-1.amazonaws.com"

# Via Console AWS: S3 → Bucket → Properties → Static website hosting
```

---

## ⚙️ **PASSO 5: PERMISSÕES IAM NECESSÁRIAS**

### **Policy S3 Full Access:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
```

### **Aplicar Permissões:**
```bash
aws iam put-role-policy \
  --role-name SUA-ROLE \
  --policy-name S3_FullAccess \
  --policy-document file://s3-policy.json
```

---

## 🔧 **CHECKLIST DE VERIFICAÇÃO**

### **Antes de Executar:**
```bash
# 1. Verificar diretório
pwd
# Deve estar no diretório raiz do projeto bia

# 2. Verificar estrutura
ls -la client/package.json
# Deve existir

# 3. Verificar dependências
ls -la client/node_modules/ | head -5
# Deve mostrar dependências instaladas

# 4. Verificar scripts
ls -la *.sh
# Deve mostrar: deploys3.sh, reacts3.sh, s3.sh
```

---

## 🚨 **PROBLEMAS COMUNS E SOLUÇÕES**

### **ERRO 1: Permissões IAM Insuficientes**
**Sintoma:**
```
AccessDenied: User is not authorized to perform: s3:CreateBucket
```

**Solução:**
```bash
aws iam put-role-policy \
  --role-name SUA-ROLE \
  --policy-name S3_FullAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }]
  }'
```

### **ERRO 2: Nome do Bucket Já Existe**
**Sintoma:**
```
BucketAlreadyExists: The requested bucket name is not available
```

**Solução:**
```bash
# Usar timestamp para nome único
aws s3api create-bucket --bucket desafios-fundamentais-bia-$(date +%s)
```

### **ERRO 3: Diretório Incorreto**
**Sintoma:**
```
package.json não encontrado em client/
```

**Solução:**
```bash
# Verificar se está no diretório correto
pwd
# Deve mostrar: /caminho/para/bia

# Se não estiver:
cd /caminho/para/bia
./deploys3.sh hom
```

### **ERRO 4: vite: not found (Caso Real)**
**Sintoma:**
```
sh: 1: vite: not found
Build do React realizado com sucesso!  ← Script mente
```

**Solução:**
```bash
# 1. Entrar na pasta client
cd client

# 2. Reinstalar dependências
npm install --force

# 3. Verificar se vite foi instalado
ls node_modules/.bin/vite

# 4. Build manual
VITE_API_URL=http://SEU-ENDPOINT npm run build

# 5. Verificar resultado
ls -la build/index.html
```

### **ERRO 5: Build Falha Silenciosamente**
**Sintoma:**
```
The user-provided path ./client/build/ does not exist
```

**Solução:**
```bash
# Verificar se build foi criado
ls -la client/build/

# Se não existir, build manual:
cd client
VITE_API_URL=http://SEU-ENDPOINT npm run build
ls -la build/  # Verificar se foi criado
cd ..
```

---

## 🧪 **CASOS REAIS TESTADOS**

### **Cenário 1: Execução do Diretório Errado**
**Erro:** `cd: client: No such file or directory`
**Solução:** Sempre executar do diretório raiz do projeto bia

### **Cenário 2: Dependências Não Instaladas**
**Erro:** `vite: command not found`
**Solução:** `cd client && npm install && cd ..`

### **Cenário 3: Estrutura de Projeto Incorreta**
**Erro:** `package.json não encontrado`
**Solução:** Clonar projeto do GitHub corretamente

---

## 💡 **LIÇÕES APRENDIDAS**

### **✅ Sucessos:**
1. **Clone do GitHub:** Garante estrutura correta
2. **VITE_API_URL:** Atualização correta do REACT_APP_API_URL
3. **Scripts com validação:** Detectam erros antes de falhar
4. **Permissões IAM:** S3FullAccess resolve todos os problemas
5. **Nome único:** Timestamp evita conflitos de bucket

### **📚 Melhorias Futuras:**
1. **CloudFront:** CDN para melhor performance
2. **Route 53:** Domínio customizado
3. **HTTPS:** Certificado SSL via ACM
4. **CI/CD:** Integração com CodePipeline
5. **Versionamento:** Deploy com tags de versão

---

## 🎯 **COMANDOS ÚTEIS**

### **Deploy Completo:**
```bash
git clone https://github.com/henrylle/bia.git
cd bia
cd client && npm install && cd ..
./deploys3.sh hom
```

### **Verificações:**
```bash
# Status do bucket
aws s3api head-bucket --bucket SEU-BUCKET-NAME

# Listar arquivos
aws s3 ls s3://SEU-BUCKET-NAME/ --recursive

# Testar site
curl http://SEU-BUCKET-NAME.s3-website-us-east-1.amazonaws.com
```

### **Limpeza:**
```bash
# Deletar arquivos
aws s3 rm s3://SEU-BUCKET-NAME/ --recursive

# Deletar bucket
aws s3api delete-bucket --bucket SEU-BUCKET-NAME
```

---

## ✅ **RESULTADO FINAL**

**DESAFIO S3 IMPLEMENTADO COM SUCESSO!**

- ✅ **Projeto clonado:** Estrutura correta do GitHub
- ✅ **Scripts criados:** Com validações e verificações
- ✅ **Site estático funcionando:** React hospedado no S3
- ✅ **Deploy automatizado:** Scripts funcionais
- ✅ **Permissões configuradas:** Acesso público e IAM
- ✅ **Troubleshooting documentado:** Soluções para problemas comuns
- ✅ **Processo replicável:** Documentação completa

---

---

## 🚀 **PLUS: SCRIPT OTIMIZADO COM VALIDAÇÕES**

### **reacts3.sh - Versão Otimizada:**
```bash
#!/bin/bash
function build() {
    API_URL=$1
    echo $API_URL
    
    # Verificar se estamos no diretório correto
    if [ ! -f "client/package.json" ]; then
        echo "❌ ERRO: package.json não encontrado em client/"
        echo "💡 Execute do diretório raiz do projeto bia"
        exit 1
    fi
    
    cd client
    
    # Instalar dependências se necessário
    if [ ! -d "node_modules" ]; then
        echo "📦 Instalando dependências..."
        npm install
    fi
    
    # Verificar se vite existe
    if [ ! -f "node_modules/.bin/vite" ]; then
        echo "❌ ERRO: vite não encontrado após npm install"
        echo "💡 Tente: npm install --force"
        exit 1
    fi
    
    echo "🚀 Iniciando build..."
    VITE_API_URL=$API_URL npm run build
    
    # Verificar se build foi criado
    if [ ! -d "build" ]; then
        echo "❌ ERRO: Build falhou - pasta build não criada"
        exit 1
    fi
    
    echo "✅ Build realizado com sucesso!"
    cd ..
}
```

### **🎯 Vantagens da Versão Otimizada:**
- ✅ **Validação de estrutura:** Verifica se package.json existe
- ✅ **Detecção de erros:** Para execução se algo falhar
- ✅ **Verificação de dependências:** Confirma se vite foi instalado
- ✅ **Validação de build:** Confirma se pasta build foi criada
- ✅ **Mensagens claras:** Indica exatamente onde está o problema
- ✅ **Prevenção de erros:** Evita problemas comuns documentados

### **📋 Quando Usar Cada Versão:**
- **Script Original:** Para seguir exatamente o desafio proposto
- **Script Otimizado:** Para ambientes de produção ou quando houver problemas

*Documentação criada em: 07/11/2025*  
*Implementação: Amazon Q + Projeto BIA*  
*Status: Desafio S3 concluído com sucesso*
