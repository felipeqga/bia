# 📋 PASSOS PARA DELETAR CLUSTER ECS - SEQUÊNCIA QUE FUNCIONA

## 🎯 **SEQUÊNCIA TESTADA E VALIDADA**

**Data:** 05/08/2025  
**Baseado em:** Deleção real executada com sucesso  

---

## 📝 **PASSO-A-PASSO:**

### **1. Desregistrar Container Instances**
```bash
# Listar instâncias
aws ecs list-container-instances --cluster cluster-bia-alb

# Desregistrar cada uma (usar os IDs retornados)
aws ecs deregister-container-instance --cluster cluster-bia-alb --container-instance INSTANCE_ID_1
aws ecs deregister-container-instance --cluster cluster-bia-alb --container-instance INSTANCE_ID_2
```

### **2. Terminar Instâncias EC2**
```bash
# Usar os IDs das EC2 obtidos no passo anterior
aws ec2 terminate-instances --instance-ids i-XXXXX i-YYYYY
```

### **3. Deletar Auto Scaling Group**
```bash
# Listar ASGs para encontrar o nome
aws autoscaling describe-auto-scaling-groups

# Deletar (usar nome completo encontrado)
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "Infra-ECS-Cluster-cluster-bia-alb-XXXXX-ECSAutoScalingGroup-XXXXX" --force-delete
```

### **4. Deletar CloudFormation Stack**
```bash
# Usar nome do stack encontrado
aws cloudformation delete-stack --stack-name "Infra-ECS-Cluster-cluster-bia-alb-XXXXX"
```

### **5. Aguardar e Deletar Cluster**
```bash
# Aguardar attachments serem atualizados
sleep 30

# Deletar cluster
aws ecs delete-cluster --cluster cluster-bia-alb
```

---

## ⚠️ **PONTOS IMPORTANTES:**

1. **Ordem é crítica** - não pular passos
2. **Aguardar 30s** antes de deletar cluster (attachments)
3. **Usar nomes completos** dos recursos (não abreviar)
4. **Verificar se cada passo funcionou** antes do próximo

---

## ✅ **RESULTADO ESPERADO:**
- Container instances: INACTIVE
- EC2 instances: terminated
- Auto Scaling Group: deletado
- CloudFormation Stack: DELETE_COMPLETE
- Cluster ECS: INACTIVE

---

*Sequência validada em: 05/08/2025 16:30 UTC*  
*Funcionou perfeitamente na primeira execução*