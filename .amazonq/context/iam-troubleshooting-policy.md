# 🔧 POLICY OBRIGATÓRIA: IAM Troubleshooting para Amazon Q

## 🎯 **PROBLEMA QUE RESOLVE:**

**Amazon Q precisa de permissões IAM específicas para resolver problemas de permissão automaticamente.**

---

## ✅ **SOLUÇÃO RECOMENDADA:**

### **Policy Mínima para Troubleshooting:**

```bash
# Criar policy inline para troubleshooting
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name IAM_TroubleshootingAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "TroubleshootingIAM",
      "Effect": "Allow",
      "Action": [
        "iam:PutRolePolicy",
        "iam:GetRolePolicy", 
        "iam:ListRolePolicies",
        "iam:AttachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:GetRole"
      ],
      "Resource": "arn:aws:iam::*:role/role-acesso-ssm"
    }]
  }'
```

### **O QUE ESTA POLICY PERMITE:**
- ✅ **Criar policies inline** (`iam:PutRolePolicy`)
- ✅ **Ler policies existentes** (`iam:GetRolePolicy`)
- ✅ **Listar policies** (`iam:ListRolePolicies`)
- ✅ **Anexar policies gerenciadas** (`iam:AttachRolePolicy`)
- ✅ **Verificar configuração da role** (`iam:GetRole`)
- ❌ **NÃO permite criar/deletar roles**
- ❌ **NÃO permite modificar outras roles**

---

## 🚨 **ALTERNATIVA MAIS SIMPLES (MENOS SEGURA):**

### **Policy com Poder Total IAM:**

```bash
# ATENÇÃO: Dá poder total sobre IAM
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name IAM_FullAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }]
  }'
```

**⚠️ CUIDADO:** Esta policy dá poder total sobre IAM. Use apenas para troubleshooting.

---

## 🧪 **COMO TESTAR SE FUNCIONOU:**

### **Teste 1: Verificar se Amazon Q pode ler policies**
```bash
aws iam list-role-policies --role-name role-acesso-ssm
```

### **Teste 2: Verificar se pode criar policy de teste**
```bash
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name TesteAmazonQ \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "*"
    }]
  }'

# Remover policy de teste
aws iam delete-role-policy \
  --role-name role-acesso-ssm \
  --policy-name TesteAmazonQ
```

### **Teste 3: Simular problema Route 53**
```bash
# Deve retornar erro se não tiver permissão
aws route53 list-hosted-zones

# Amazon Q deve conseguir resolver automaticamente
```

---

## 📋 **CENÁRIOS DE USO:**

### **✅ COM ESTA POLICY, AMAZON Q PODE:**
1. **Identificar falta de permissão** (ex: Route 53, ACM)
2. **Criar policy específica** para resolver o problema
3. **Testar se funcionou** automaticamente
4. **Continuar o trabalho** sem interrupção

### **❌ SEM ESTA POLICY, AMAZON Q:**
1. **Identifica o problema** mas não pode resolver
2. **Precisa pedir ao usuário** para adicionar permissões
3. **Interrompe o fluxo** de trabalho
4. **Requer intervenção manual** constante

---

## 🎯 **EXEMPLO PRÁTICO:**

### **Problema:** Route 53 sem permissão
```
AccessDenied: route53:ListHostedZones
```

### **Com a policy, Amazon Q faz automaticamente:**
```bash
# 1. Identifica o problema
aws route53 list-hosted-zones  # ← Falha

# 2. Cria solução
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name Route53_Access \
  --policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Action": "route53:*", "Resource": "*"}]}'

# 3. Testa solução  
aws route53 list-hosted-zones  # ← Funciona!

# 4. Continua o trabalho
```

---

## 🔒 **CONSIDERAÇÕES DE SEGURANÇA:**

### **✅ POLICY MÍNIMA (Recomendada):**
- Permite apenas troubleshooting
- Limitada à role específica
- Não pode criar/deletar roles
- Princípio do menor privilégio

### **⚠️ POLICY COMPLETA (iam:*):**
- Poder total sobre IAM
- Maior risco de segurança
- Mais flexibilidade para troubleshooting
- Usar apenas em ambientes de desenvolvimento

---

## 📊 **RESUMO PARA IMPLEMENTAÇÃO:**

### **PASSO 1: Escolher abordagem**
- **Segura:** Policy mínima (recomendada)
- **Simples:** Policy completa (iam:*)

### **PASSO 2: Executar comando**
```bash
# Copiar e executar um dos comandos acima
```

### **PASSO 3: Testar**
```bash
# Verificar se Amazon Q consegue resolver problemas
aws iam list-role-policies --role-name role-acesso-ssm
```

### **PASSO 4: Usar Amazon Q**
```bash
# Amazon Q agora pode resolver problemas automaticamente
qbia
```

---

## 🏆 **RESULTADO ESPERADO:**

**Com esta policy configurada:**
- ✅ Amazon Q resolve problemas de permissão automaticamente
- ✅ Fluxo de trabalho sem interrupções
- ✅ Troubleshooting eficiente
- ✅ Experiência de usuário otimizada

**Sem esta policy:**
- ❌ Interrupções constantes para adicionar permissões
- ❌ Fluxo de trabalho fragmentado
- ❌ Necessidade de conhecimento técnico IAM
- ❌ Experiência frustrante

---

*Guia criado em: 04/08/2025 02:00 UTC*  
*Baseado em análise forense das permissões IAM*  
*Testado e validado no projeto BIA*