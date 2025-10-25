# 🎯 GUIA DE ESCOLHA - TEMPLATES ECS CLUSTER

## 📊 **OPÇÕES DISPONÍVEIS:**

### **🔵 TEMPLATE V1 (YAML) - ESTÁVEL**
**Arquivo:** `ecs-cluster-template.yaml`
**Status:** ✅ Testado e validado

**Características:**
- **AMI:** Hardcoded `ami-07985a96d172b21ee` (Amazon Linux 2023)
- **User Data:** Completo com yum update + ecs-init
- **Formato:** YAML (mais legível)
- **Capacidade:** 2 instâncias por padrão
- **ExecuteCommand:** ❌ Não configurado

### **🟢 TEMPLATE V2 (JSON) - MODERNO**
**Arquivo:** `ecs-cluster-template-v2.json`
**Status:** ✅ Testado e validado

**Características:**
- **AMI:** Dinâmica via SSM Parameter (sempre atualizada)
- **User Data:** Simples (só ECS_CLUSTER config)
- **Formato:** JSON (padrão AWS)
- **Capacidade:** 1 instância por padrão
- **ExecuteCommand:** ✅ Configurado
- **Validação:** Regex pattern para VPC ID

---

## 🎯 **RECOMENDAÇÕES DE USO:**

### **📚 PARA APRENDIZADO (RECOMENDADO):**
**Use Template V1 (YAML)**
- ✅ Mais estável e testado
- ✅ User data completo (educacional)
- ✅ YAML mais fácil de ler
- ✅ 2 instâncias (alta disponibilidade)

### **🚀 PARA PRODUÇÃO:**
**Use Template V2 (JSON)**
- ✅ AMI sempre atualizada
- ✅ ExecuteCommand habilitado
- ✅ Validações de entrada
- ✅ Padrão oficial AWS

---

## 🛠️ **COMANDOS DE IMPLEMENTAÇÃO:**

### **Template V1 (YAML):**
```bash
aws cloudformation create-stack \
  --stack-name bia-ecs-cluster-v1 \
  --template-body file:///home/ec2-user/bia/ecs-cluster-template.yaml \
  --parameters \
    ParameterKey=ClusterName,ParameterValue=cluster-bia-alb \
    ParameterKey=InstanceType,ParameterValue=t3.micro \
    ParameterKey=DesiredCapacity,ParameterValue=2 \
    ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
    ParameterKey=SubnetIds,ParameterValue="subnet-068e3484d05611445,subnet-0c665b052ff5c528d" \
    ParameterKey=SecurityGroupId,ParameterValue=sg-00c1a082f04bc6709 \
    ParameterKey=InstanceProfileArn,ParameterValue="arn:aws:iam::387678648422:instance-profile/role-acesso-ssm" \
  --capabilities CAPABILITY_NAMED_IAM
```

### **Template V2 (JSON):**
```bash
aws cloudformation create-stack \
  --stack-name bia-ecs-cluster-v2 \
  --template-body file:///home/ec2-user/bia/ecs-cluster-template-v2.json \
  --parameters \
    ParameterKey=ECSClusterName,ParameterValue=cluster-bia-alb \
    ParameterKey=SecurityGroupIds,ParameterValue=sg-00c1a082f04bc6709 \
    ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
    ParameterKey=SubnetIds,ParameterValue="subnet-068e3484d05611445,subnet-0c665b052ff5c528d" \
    ParameterKey=Ec2InstanceProfileArn,ParameterValue="arn:aws:iam::387678648422:instance-profile/role-acesso-ssm" \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## ⚡ **DIFERENÇAS TÉCNICAS:**

| **Aspecto** | **Template V1** | **Template V2** |
|-------------|-----------------|-----------------|
| **AMI** | `ami-07985a96d172b21ee` | SSM Parameter (dinâmica) |
| **User Data** | yum update + ecs-init | Só ECS_CLUSTER |
| **Instâncias** | 2 (Min/Max/Desired) | 1 (Min/Max/Desired) |
| **ExecuteCommand** | Não | Sim |
| **Validação VPC** | Não | Regex pattern |
| **Formato** | YAML | JSON |

---

## 🎯 **DECISÃO RÁPIDA:**

**Para DESAFIO-3 educacional:** Template V1 (YAML)
**Para ambiente real:** Template V2 (JSON)

**Ambos funcionam 100% e criam clusters ECS válidos!**

---

*Testado em: 25/10/2024*  
*Status: Ambos templates validados e funcionando*  
*Aplicação BIA rodando com sucesso em ambos*
