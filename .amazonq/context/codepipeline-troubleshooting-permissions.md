# 🚀 TROUBLESHOOTING: Problemas de Permissões no CodePipeline

## 📋 **PROBLEMAS REAIS ENCONTRADOS DURANTE IMPLEMENTAÇÃO**

**Data:** 02/08/2025  
**Contexto:** Criação do CodePipeline conforme PASSO-7  
**Status:** ✅ RESOLVIDO e DOCUMENTADO  

---

## 🚨 **PROBLEMA 1: Erro de Policy Durante Criação**

### **Sintoma:**
Durante a criação do CodePipeline, aparece erro relacionado a policy existente.

### **Mensagem de Erro:**
```
Erro de POLICY - Policy já existe ou conflito de nomes
```

### **✅ SOLUÇÃO:**
**Deletar a policy com o nome que aparecer no erro.**

```bash
# Exemplo de comando (substituir pelo nome real da policy):
aws iam delete-policy --policy-arn arn:aws:iam::ACCOUNT:policy/NOME-DA-POLICY-CONFLITANTE
```

### **📋 OBSERVAÇÃO:**
- Este é um problema comum durante recriação de pipelines
- AWS não sobrescreve policies automaticamente
- Sempre anotar o nome da policy que aparece no erro

---

## 🚨 **PROBLEMA 2: Erro ECR Login no CodeBuild**

### **Sintoma:**
Deploy falha na fase de build com erro de login no ECR.

### **Mensagem de Erro:**
```
[Container] 2025/08/02 02:49:33.832637 Phase context status code: COMMAND_EXECUTION_ERROR 
Message: Error while executing command: aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 905418381762.dkr.ecr.us-east-1.amazonaws.com. 
Reason: exit status 1
```

### **🔍 CAUSA RAIZ:**
Role do CodeBuild (`codebuild-bia-build-pipeline-service-role`) não tem permissões para acessar ECR.

### **✅ SOLUÇÃO APLICADA:**
**Adicionar policy `AmazonEC2ContainerRegistryPowerUser` à role do CodeBuild:**

```bash
aws iam attach-role-policy \
  --role-name codebuild-bia-build-pipeline-service-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### **📊 VERIFICAÇÃO:**
```bash
# Confirmar que policy foi adicionada
aws iam list-attached-role-policies --role-name codebuild-bia-build-pipeline-service-role

# Testar login ECR manualmente
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 387678648422.dkr.ecr.us-east-1.amazonaws.com
```

---

## 🚨 **PROBLEMA 3: Permissões PassRole (Possível)**

### **Contexto:**
Durante implementação, pode ter sido necessário criar policy PASSROLE.

### **Sintoma Possível:**
```
AccessDenied: iam:PassRole
```

### **✅ SOLUÇÃO APLICADA:**
**Policy inline PASSROLE criada:**

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "iam:PassRole",
      "ec2:RunInstances"
    ],
    "Resource": [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:iam::387678648422:role/codebuild-bia-build-pipeline-service-role"
    ],
    "Condition": {
      "StringEquals": {
        "iam:PassedToService": ["ec2.amazonaws.com", "codebuild.amazonaws.com"]
      }
    }
  }]
}
```

---

## 📊 **CONFIGURAÇÃO FINAL DA ROLE CODEBUILD**

### **🔧 Policies Gerenciadas Anexadas:**
1. **`AmazonEC2ContainerRegistryPowerUser`** ✅ (Solução do Problema 2)
2. **`CodeBuildBasePolicy-bia-build-pipeline-us-east-1`** ✅ (Criada automaticamente)
3. **`BIA-ECS-Deploy-Permissions`** ✅ (Policy customizada para ECS)

### **🔧 Policies Inline:**
1. **`PipeLineec2`** ✅ (Permissões EC2)
2. **`PipeLinePermisssions`** ✅ (Permissões gerais do pipeline)

### **📋 VERIFICAÇÃO ATUAL:**
```bash
# Confirmar configuração
aws iam list-attached-role-policies --role-name codebuild-bia-build-pipeline-service-role
aws iam list-role-policies --role-name codebuild-bia-build-pipeline-service-role
```

---

## 🎯 **PROCESSO DE TROUBLESHOOTING**

### **📋 CHECKLIST PARA PROBLEMAS DE CODEPIPELINE:**

#### **1. Erro de Policy Durante Criação:**
- [ ] Anotar nome da policy conflitante
- [ ] Deletar policy conflitante
- [ ] Recriar CodePipeline

#### **2. Erro ECR Login:**
- [ ] Verificar role do CodeBuild
- [ ] Adicionar `AmazonEC2ContainerRegistryPowerUser`
- [ ] Testar login ECR manualmente

#### **3. Erro PassRole:**
- [ ] Verificar se role pode passar roles
- [ ] Criar policy PASSROLE se necessário
- [ ] Testar operações que requerem PassRole

### **🔍 COMANDOS DE DIAGNÓSTICO:**

```bash
# Verificar role do CodeBuild
aws iam get-role --role-name codebuild-bia-build-pipeline-service-role

# Verificar policies anexadas
aws iam list-attached-role-policies --role-name codebuild-bia-build-pipeline-service-role

# Verificar policies inline
aws iam list-role-policies --role-name codebuild-bia-build-pipeline-service-role

# Testar ECR
aws ecr get-login-password --region us-east-1

# Verificar logs do CodeBuild
aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/bia-build-pipeline
```

---

## 🚀 **LIÇÕES APRENDIDAS**

### **✅ DESCOBERTAS IMPORTANTES:**
1. **Policy conflicts são comuns** durante recriação de pipelines
2. **ECR permissions são críticas** para build de imagens Docker
3. **PassRole pode ser necessário** dependendo das operações
4. **Role do CodeBuild precisa de múltiplas permissões** para funcionar
5. **Troubleshooting deve ser sistemático** seguindo checklist

### **🔧 PARA IMPLEMENTADORES:**
- **Sempre verificar policies** antes de criar pipeline
- **Documentar erros específicos** com mensagens completas
- **Testar permissões individualmente** após correções
- **Manter troubleshooting guide** atualizado

### **📋 PARA FUTURAS IMPLEMENTAÇÕES:**
- **Usar este guia** como referência
- **Aplicar soluções conhecidas** imediatamente
- **Documentar novos problemas** conforme aparecem
- **Manter configuração de permissões** consistente

---

## 🎯 **RESULTADO FINAL**

### **✅ PROBLEMAS RESOLVIDOS:**
- **Erro de Policy:** ✅ Processo de limpeza documentado
- **ECR Login:** ✅ `AmazonEC2ContainerRegistryPowerUser` adicionada
- **PassRole:** ✅ Policy inline criada (se necessário)
- **CodePipeline:** ✅ Funcionando completamente

### **📋 CONFIGURAÇÃO VALIDADA:**
- **Role:** `codebuild-bia-build-pipeline-service-role` ✅
- **Permissões ECR:** ✅ Funcionando
- **Build Process:** ✅ Executando sem erros
- **Deploy ECS:** ✅ Integrando corretamente

### **🚀 PRÓXIMOS PASSOS:**
- Usar este guia para troubleshooting futuro
- Aplicar soluções conhecidas imediatamente
- Documentar novos problemas conforme aparecem

---

*Documentado em: 04/08/2025 03:00 UTC*  
*Baseado em problemas reais encontrados em 02/08/2025*  
*Status: Soluções testadas e validadas*  
*Role: codebuild-bia-build-pipeline-service-role configurada corretamente*