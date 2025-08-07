# 🚀 TROUBLESHOOTING: Problemas de Permissões no CodePipeline

## 📋 **PROBLEMAS REAIS ENCONTRADOS DURANTE IMPLEMENTAÇÃO**

**Data:** 02/08/2025 + **ATUALIZADO:** 07/08/2025  
**Contexto:** Criação do CodePipeline conforme PASSO-7  
**Status:** ✅ RESOLVIDO e DOCUMENTADO + **NOVOS ERROS IDENTIFICADOS**

## ⚠️ **ERRO CRÍTICO DO AMAZON Q (07/08/2025):**
**Amazon Q não consultou esta documentação existente antes de fazer troubleshooting, resultando em tentativas desnecessárias e APIs erradas. SEMPRE consultar documentação existente primeiro!**

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

---

## 🚨 **PROBLEMA 3: Erro de Conexão GitHub (CodeStar Connections)**

### **Sintoma:**
```
Unable to use Connection: arn:aws:codeconnections:us-east-1:387678648422:connection/720e8e0c-9d0d-4b61-bc29-a5c9302b5992. 
The provided role does not have sufficient permissions.
```

### **🔍 CAUSA RAIZ:**
Role do CodePipeline não tem permissões para usar conexões GitHub (CodeStar Connections).

### **❌ TENTATIVAS ERRADAS (NÃO FUNCIONAM):**
```json
// API ERRADA - não funciona
{
  "Action": ["codeconnections:UseConnection", "codeconnections:GetConnection"]
}
```

### **✅ SOLUÇÃO CORRETA:**
**API correta é `codestar-connections` (não `codeconnections`):**

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "codestar-connections:PassConnection",
      "codestar-connections:UseConnection"
    ],
    "Resource": "*"
  }]
}
```

### **🔧 COMANDO PARA APLICAR:**
```bash
aws iam put-role-policy \
  --role-name AWSCodePipelineServiceRole-us-east-1-bia-TESTE \
  --policy-name CodeStarConnections_PassConnection \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "codestar-connections:PassConnection",
        "codestar-connections:UseConnection"
      ],
      "Resource": "*"
    }]
  }'
```

### **🎯 CONFIGURAÇÃO ROBUSTA (RECOMENDADA):**
**Para máxima compatibilidade, usar permissões amplas:**

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["codeconnections:*"],
    "Resource": "*"
  }]
}
```

---

## 🚨 **PROBLEMA 4: Role Incompleta vs Role Robusta**

### **📊 COMPARAÇÃO DE ROLES:**

#### **✅ Role Original (Funciona em Todos os Cenários):**
```
AWSCodePipelineServiceRole-us-east-1-bia
├── CodePipelineCorrectPermissions (específicas)
├── CodePipelineFullPermissions (amplas: codeconnections:*, s3:*, codebuild:*, ecs:*)
└── CodeStarConnections_PassConnection
```

#### **⚠️ Role Nova (Funciona Apenas no Cenário Atual):**
```
AWSCodePipelineServiceRole-us-east-1-bia-TESTE
├── CodeConnectionsAccess (API errada - corrigida)
├── CodePipelineBasicPermissions (limitadas)
├── CodeStarConnections_PassConnection (copiada)
└── CodePipelineFullPermissions (adicionada depois)
```

### **🎯 RECOMENDAÇÃO:**
- **Para produção:** Use role original (robusta)
- **Para troubleshooting:** Role nova ajuda a identificar permissões específicas

---

## 🎯 **PROCESSO DE TROUBLESHOOTING CORRIGIDO**

### **📋 CHECKLIST PARA PROBLEMAS DE CODEPIPELINE:**

#### **0. ANTES DE TUDO:**
- [ ] **🚨 OBRIGATÓRIO:** Ler esta documentação completa
- [ ] Verificar se problema já foi resolvido antes
- [ ] Comparar com configurações que funcionam

#### **1. Erro de Policy Durante Criação:**
- [ ] Anotar nome da policy conflitante
- [ ] Deletar policy conflitante
- [ ] Recriar CodePipeline

#### **2. Erro ECR Login:**
- [ ] Verificar role do CodeBuild
- [ ] Adicionar `AmazonEC2ContainerRegistryPowerUser`
- [ ] Testar login ECR manualmente

#### **3. Erro Conexão GitHub:**
- [ ] **PRIMEIRO:** Consultar esta documentação!
- [ ] Verificar se role tem `codestar-connections:UseConnection`
- [ ] **NÃO usar** `codeconnections` (API errada)
- [ ] Aplicar policy correta com `codestar-connections`
- [ ] Testar pipeline após correção

#### **4. Erro PassRole:**
- [ ] Verificar se role pode passar roles
- [ ] Criar policy PASSROLE se necessário
- [ ] Testar operações que requerem PassRole

---

## 🚀 **LIÇÕES APRENDIDAS**

### **✅ DESCOBERTAS IMPORTANTES:**
1. **Policy conflicts são comuns** durante recriação de pipelines
2. **ECR permissions são críticas** para build de imagens Docker
3. **PassRole pode ser necessário** dependendo das operações
4. **Role do CodeBuild precisa de múltiplas permissões** para funcionar
5. **Troubleshooting deve ser sistemático** seguindo checklist
6. **🚨 NOVA:** API correta é `codestar-connections` (não `codeconnections`)
7. **🚨 NOVA:** Sempre consultar documentação existente PRIMEIRO
8. **🚨 NOVA:** Role original tem permissões mais robustas (`codeconnections:*`)

### **🔧 PARA IMPLEMENTADORES:**
- **🚨 PRIMEIRO:** Consultar documentação existente antes de troubleshooting
- **Sempre verificar policies** antes de criar pipeline
- **Documentar erros específicos** com mensagens completas
- **Testar permissões individualmente** após correções
- **Manter troubleshooting guide** atualizado
- **Comparar com configurações que funcionaram antes**

### **📋 PARA FUTURAS IMPLEMENTAÇÕES:**
- **🚨 OBRIGATÓRIO:** Ler esta documentação ANTES de fazer troubleshooting
- **Usar este guia** como referência
- **Aplicar soluções conhecidas** imediatamente
- **Documentar novos problemas** conforme aparecem
- **Manter configuração de permissões** consistente
- **Copiar configurações de roles que funcionam**

### **🤖 PARA AMAZON Q:**
- **🚨 CRÍTICO:** SEMPRE consultar documentação existente primeiro
- **Não "chutar" soluções** quando já existe documentação
- **Reconhecer contexto** (ex: "criando CodePipeline" = consultar docs de CodePipeline)
- **Comparar com configurações que funcionaram**
- **Documentar erros próprios** para aprendizado

---

## 🎯 **RESULTADO FINAL**

### **✅ PROBLEMAS RESOLVIDOS:**
- **Erro de Policy:** ✅ Processo de limpeza documentado
- **ECR Login:** ✅ `AmazonEC2ContainerRegistryPowerUser` adicionada
- **Conexão GitHub:** ✅ `codestar-connections` API correta identificada
- **PassRole:** ✅ Policy inline criada (se necessário)
- **CodePipeline:** ✅ Funcionando completamente
- **Erro Amazon Q:** ✅ Processo corrigido e documentado

### **📋 CONFIGURAÇÃO VALIDADA:**
- **Role:** `codebuild-bia-build-pipeline-service-role` ✅
- **Permissões ECR:** ✅ Funcionando
- **Conexões GitHub:** ✅ API correta aplicada
- **Build Process:** ✅ Executando sem erros
- **Deploy ECS:** ✅ Integrando corretamente

### **🚀 PRÓXIMOS PASSOS:**
- Usar este guia para troubleshooting futuro
- Aplicar soluções conhecidas imediatamente
- Documentar novos problemas conforme aparecem
- **Amazon Q deve consultar docs existentes PRIMEIRO**

---

## 📊 **COMANDOS DE VERIFICAÇÃO FINAL**

### **Verificar Role do CodePipeline:**
```bash
# Listar policies da role
aws iam list-role-policies --role-name AWSCodePipelineServiceRole-us-east-1-bia-TESTE

# Verificar policy específica
aws iam get-role-policy --role-name AWSCodePipelineServiceRole-us-east-1-bia-TESTE --policy-name CodeStarConnections_PassConnection

# Testar pipeline
aws codepipeline start-pipeline-execution --name bia
```

### **Comparar com Role Original:**
```bash
# Role que funciona
aws iam list-role-policies --role-name AWSCodePipelineServiceRole-us-east-1-bia

# Comparar permissões
aws iam get-role-policy --role-name AWSCodePipelineServiceRole-us-east-1-bia --policy-name CodePipelineFullPermissions
```

---

*Documentado em: 04/08/2025 03:00 UTC*  
*Atualizado em: 07/08/2025 01:00 UTC*  
*Baseado em problemas reais encontrados em 02/08/2025 + 07/08/2025*  
*Status: Soluções testadas e validadas*  
*Role: codebuild-bia-build-pipeline-service-role configurada corretamente*  
*ERRO AMAZON Q: Não consultou documentação existente - CORRIGIDO*  
*LIÇÃO: Sempre ler documentação existente PRIMEIRO*