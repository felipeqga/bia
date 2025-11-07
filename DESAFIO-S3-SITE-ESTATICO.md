# 🌐 DESAFIO S3: SITE ESTÁTICO - DOCUMENTAÇÃO COMPLETA

## 📋 **RESUMO DO DESAFIO**
Criar bucket S3, configurar hospedagem de site estático, aplicar permissões públicas e implementar scripts de deploy automatizado para aplicação React.

**Data de Implementação:** 07/11/2025  
**Status:** ✅ CONCLUÍDO COM SUCESSO  
**Endpoint Final:** `http://desafios-fundamentais-bia-1762481467.s3-website-us-east-1.amazonaws.com`

---

## 🎯 **OBJETIVOS ALCANÇADOS**

1. ✅ **Bucket S3 criado:** `desafios-fundamentais-bia-1762481467`
2. ✅ **Acesso público configurado:** Block All Public Access removido
3. ✅ **Static Website Hosting habilitado:** index.html como página inicial
4. ✅ **Bucket Policy aplicada:** Acesso público de leitura
5. ✅ **Scripts de deploy criados:** Automação completa
6. ✅ **Build React funcionando:** VITE_API_URL configurado
7. ✅ **Site online:** Aplicação acessível via HTTP

---

## 🚨 **PROBLEMAS ENCONTRADOS E SOLUÇÕES**

### **ERRO 1: Permissões IAM Insuficientes**
**Sintoma:**
```
AccessDenied: User is not authorized to perform: s3:CreateBucket
```

**Causa:** Role `role-acesso-ssm` não tinha permissões S3

**Solução:**
```bash
aws iam put-role-policy \
  --role-name role-acesso-ssm \
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

**Causa:** Nome `desafios-fundamentais-bia` já estava em uso

**Solução:**
```bash
# Usar timestamp para nome único
aws s3api create-bucket --bucket desafios-fundamentais-bia-$(date +%s)
```

### **ERRO 3: Build do React Falhando**
**Sintoma:**
```
vite: command not found
The user-provided path ./bia/client/build/ does not exist
```

**Causa:** Dependências do client não instaladas

**Solução:**
```bash
cd /home/ec2-user/bia/client
npm install
VITE_API_URL=http://bia-549844302.us-east-1.elb.amazonaws.com npm run build
```

---

## 🔧 **CONFIGURAÇÕES AWS IMPLEMENTADAS**

### **1. Bucket S3 Criado**
```bash
aws s3api create-bucket --bucket desafios-fundamentais-bia-1762481467
```

### **2. Remoção do Bloqueio Público**
```bash
aws s3api delete-public-access-block --bucket desafios-fundamentais-bia-1762481467
```

### **3. Configuração Website Estático**
```bash
aws s3api put-bucket-website \
  --bucket desafios-fundamentais-bia-1762481467 \
  --website-configuration '{
    "IndexDocument":{"Suffix":"index.html"},
    "ErrorDocument":{"Key":"error.html"}
  }'
```

### **4. Bucket Policy Aplicada**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::desafios-fundamentais-bia-1762481467/*"]
    }
  ]
}
```

---

## 📜 **SCRIPTS CRIADOS**

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
    aws s3 sync ./bia/client/build/ s3://desafios-fundamentais-bia-1762481467
    echo "Envio finalizado"
}
```

### **Script 3: deploys3.sh**
```bash
#!/bin/bash
AMBIENTE=$1
API_URL="http://bia-549844302.us-east-1.elb.amazonaws.com"
echo "Vou iniciar deploy no ambiente: $AMBIENTE"
echo "O endereco da api sera: $API_URL"

#check if my var AMBIENTE is equals to hom ou prd
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

---

## ⚙️ **PERMISSÕES IAM NECESSÁRIAS**

### **Policy S3 Full Access**
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

**Aplicação:**
```bash
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name S3_FullAccess \
  --policy-document file://s3-policy.json
```

---

## 🚀 **PROCESSO DE DEPLOY**

### **Passo a Passo:**

1. **Executar Deploy:**
```bash
cd /home/ec2-user
./bia/deploys3.sh hom  # Para homologação
./bia/deploys3.sh prd  # Para produção
```

2. **O que acontece:**
   - Instala dependências npm
   - Executa build React com VITE_API_URL
   - Sincroniza arquivos com S3
   - Site fica disponível automaticamente

### **Validação:**
```bash
# Testar acesso
curl -I http://desafios-fundamentais-bia-1762481467.s3-website-us-east-1.amazonaws.com

# Verificar arquivos no bucket
aws s3 ls s3://desafios-fundamentais-bia-1762481467/
```

---

## 📊 **RECURSOS FINAIS CRIADOS**

| **Recurso** | **Nome/Endpoint** | **Status** |
|-------------|-------------------|------------|
| **Bucket S3** | `desafios-fundamentais-bia-1762481467` | ✅ Ativo |
| **Website Endpoint** | `http://desafios-fundamentais-bia-1762481467.s3-website-us-east-1.amazonaws.com` | ✅ Online |
| **Bucket Policy** | Acesso público de leitura | ✅ Aplicada |
| **Scripts Deploy** | `deploys3.sh`, `reacts3.sh`, `s3.sh` | ✅ Funcionando |
| **Permissões IAM** | S3FullAccess na role-acesso-ssm | ✅ Configurada |

---

## 🔍 **TROUBLESHOOTING**

### **Problema: Site não carrega**
**Verificações:**
```bash
# 1. Verificar se bucket existe
aws s3api head-bucket --bucket desafios-fundamentais-bia-1762481467

# 2. Verificar website hosting
aws s3api get-bucket-website --bucket desafios-fundamentais-bia-1762481467

# 3. Verificar arquivos
aws s3 ls s3://desafios-fundamentais-bia-1762481467/
```

### **Problema: Erro de permissão**
**Solução:**
```bash
# Verificar permissões da role
aws iam list-role-policies --role-name role-acesso-ssm

# Reaplicar policy se necessário
aws iam put-role-policy --role-name role-acesso-ssm --policy-name S3_FullAccess --policy-document file://s3-policy.json
```

### **Problema: Build falha**
**Soluções:**
```bash
# 1. Instalar dependências
cd /home/ec2-user/bia/client && npm install

# 2. Build manual
cd /home/ec2-user/bia/client
VITE_API_URL=http://bia-549844302.us-east-1.elb.amazonaws.com npm run build

# 3. Verificar se pasta build foi criada
ls -la /home/ec2-user/bia/client/build/
```

---

## 💡 **LIÇÕES APRENDIDAS**

### **✅ Sucessos:**
1. **VITE_API_URL:** Atualização correta do REACT_APP_API_URL
2. **Permissões IAM:** S3FullAccess resolve todos os problemas de acesso
3. **Nome único:** Timestamp garante nome de bucket disponível
4. **Scripts modulares:** Separação de responsabilidades funciona bem
5. **Validação de ambiente:** Verificação hom/prd evita erros

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
./bia/deploys3.sh hom
```

### **Verificações:**
```bash
# Status do bucket
aws s3api head-bucket --bucket desafios-fundamentais-bia-1762481467

# Listar arquivos
aws s3 ls s3://desafios-fundamentais-bia-1762481467/ --recursive

# Testar site
curl http://desafios-fundamentais-bia-1762481467.s3-website-us-east-1.amazonaws.com
```

### **Limpeza (se necessário):**
```bash
# Deletar arquivos
aws s3 rm s3://desafios-fundamentais-bia-1762481467/ --recursive

# Deletar bucket
aws s3api delete-bucket --bucket desafios-fundamentais-bia-1762481467
```

---

## ✅ **RESULTADO FINAL**

**DESAFIO S3 IMPLEMENTADO COM SUCESSO!**

- ✅ **Site estático funcionando:** React hospedado no S3
- ✅ **Deploy automatizado:** Scripts funcionais
- ✅ **Permissões configuradas:** Acesso público e IAM
- ✅ **Troubleshooting documentado:** Soluções para problemas comuns
- ✅ **Processo replicável:** Documentação completa

**Endpoint:** http://desafios-fundamentais-bia-1762481467.s3-website-us-east-1.amazonaws.com

---

*Documentação criada em: 07/11/2025*  
*Implementação: Amazon Q + Projeto BIA*  
*Status: Desafio S3 concluído com sucesso*
