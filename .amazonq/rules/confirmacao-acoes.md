# ⚠️ REGRA OBRIGATÓRIA: Confirmação de Ações - Amazon Q

## 🚨 **REGRA CRÍTICA PARA AMAZON Q**

**SEMPRE perguntar ao usuário ANTES de executar qualquer ação que modifique recursos AWS.**

---

## 📋 **AÇÕES QUE REQUEREM CONFIRMAÇÃO OBRIGATÓRIA:**

### **🗑️ AÇÕES DE DELEÇÃO (CRÍTICAS):**
- `delete-db-instance`
- `delete-security-group`
- `delete-log-group`
- `delete-project` (CodeBuild)
- `delete-stack` (CloudFormation)
- `delete-load-balancer`
- `delete-cluster` (ECS)
- `terminate-instances`
- `delete-repository` (ECR)
- `delete-pipeline` (CodePipeline)

### **🔧 AÇÕES DE MODIFICAÇÃO (IMPORTANTES):**
- `modify-db-instance`
- `update-service` (ECS)
- `disassociate-address`
- `stop-instances`
- `start-instances`
- `reboot-instances`
- `modify-target-group`
- `update-project` (CodeBuild)

### **✅ AÇÕES PERMITIDAS SEM CONFIRMAÇÃO:**
- `describe-*` (todas as consultas)
- `list-*` (todas as listagens)
- `get-*` (obter informações)

---

## 🎯 **PROCESSO OBRIGATÓRIO:**

### **ANTES DE QUALQUER AÇÃO:**
1. **Explicar** o que será feito
2. **Mostrar** o comando que será executado
3. **Perguntar** explicitamente: "Posso executar esta ação?"
4. **Aguardar** confirmação do usuário
5. **Só então** executar o comando

### **EXEMPLO CORRETO:**
```
Identifiquei que podemos deletar o Security Group 'test-sg' que não está sendo usado.

Comando que será executado:
aws ec2 delete-security-group --group-id sg-0198991c9ba71db7f

Posso executar esta ação de deleção?
```

### **❌ EXEMPLO INCORRETO:**
```
Vou deletar o Security Group órfão...
[executa comando sem perguntar]
```

---

## 🔍 **EXCEÇÕES (RARAS):**

### **Situações onde confirmação pode ser implícita:**
1. **Usuário solicita explicitamente:** "Delete todos os logs"
2. **Emergência crítica:** Recursos gerando custos altos
3. **Comando específico dado:** "Execute: aws ec2 delete-security-group..."

### **⚠️ MESMO ASSIM:**
- Sempre explicar o que será feito
- Mostrar impacto da ação
- Confirmar entendimento

---

## 💡 **BENEFÍCIOS DESTA REGRA:**

### **Para o Usuário:**
- ✅ Controle total sobre modificações
- ✅ Transparência nas ações
- ✅ Prevenção de erros custosos
- ✅ Confiança no assistente

### **Para Amazon Q:**
- ✅ Evita ações indesejadas
- ✅ Mantém confiança do usuário
- ✅ Reduz riscos operacionais
- ✅ Melhora experiência

---

## 🎯 **IMPLEMENTAÇÃO:**

### **Template de Confirmação:**
```markdown
## 🔧 **AÇÃO PROPOSTA:**
[Descrição da ação]

## 📋 **COMANDO(S) A EXECUTAR:**
```bash
[comando aws cli]
```

## 💰 **IMPACTO:**
- Custo: [economia/custo]
- Reversibilidade: [sim/não]
- Risco: [baixo/médio/alto]

## ❓ **CONFIRMAÇÃO:**
Posso executar esta ação?
```

---

## 🚨 **CONSEQUÊNCIAS DE NÃO SEGUIR:**

### **❌ Problemas:**
- Perda de confiança do usuário
- Ações indesejadas executadas
- Possíveis custos desnecessários
- Recursos deletados por engano

### **✅ Solução:**
- **SEMPRE** perguntar antes
- **NUNCA** assumir permissão
- **EXPLICAR** antes de agir
- **CONFIRMAR** entendimento

---

*Regra criada em: 18/08/2025*  
*Motivo: Prevenção de ações não autorizadas*  
*Status: OBRIGATÓRIA para Amazon Q*  
*Prioridade: CRÍTICA*
