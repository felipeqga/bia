# 🚀 TEMPLATE ECS CLUSTER MELHORADO - DESAFIO-3

## 📋 **VISÃO GERAL**

Template CloudFormation completo baseado na **documentação oficial da AWS** com todas as melhores práticas implementadas. Resolve todos os problemas identificados e adiciona recursos avançados.

---

## ✨ **MELHORIAS IMPLEMENTADAS**

### **🔧 1. CloudFormation Signals**
```yaml
# Resolve o problema de timeout do Auto Scaling Group
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource ECSAutoScalingGroup --region ${AWS::Region}
```
**Benefício:** CloudFormation aguarda confirmação das instâncias antes de considerar sucesso

### **🎯 2. Systems Manager Parameter para AMI**
```yaml
ECSOptimizedAMIParameter:
  Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
  Default: /aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id
```
**Benefício:** AMI sempre atualizada automaticamente pela AWS

### **🔄 3. Launch Template Versionado**
```yaml
LaunchTemplate:
  LaunchTemplateId: !Ref ECSLaunchTemplate
  Version: !GetAtt ECSLaunchTemplate.LatestVersionNumber
```
**Benefício:** Controle de versões e rollback seguro

### **🛡️ 4. Segurança IMDSv2**
```yaml
MetadataOptions:
  HttpTokens: required
  HttpPutResponseHopLimit: 2
  HttpEndpoint: enabled
```
**Benefício:** Proteção contra ataques SSRF

### **📊 5. CloudWatch Logs**
```yaml
ECSLogGroup:
  Type: AWS::Logs::LogGroup
  LogGroupName: !Sub "/ecs/${ClusterName}"
  RetentionInDays: 7
```
**Benefício:** Logs centralizados e organizados

### **🏷️ 6. Tags Padronizadas**
```yaml
Tags:
  - Key: Project
    Value: BIA
  - Key: Environment
    Value: Production
  - Key: ClusterName
    Value: !Ref ClusterName
```
**Benefício:** Organização e billing por projeto

### **⚙️ 7. ECS Agent Health Check**
```bash
# Aguarda ECS Agent estar pronto antes de sinalizar sucesso
until curl -s http://localhost:51678/v1/metadata
do
  echo "Aguardando ECS Agent..."
  sleep 5
done
```
**Benefício:** Garante que instâncias estão realmente prontas

### **🔄 8. Rolling Update Policy**
```yaml
UpdatePolicy:
  AutoScalingRollingUpdate:
    MinInstancesInService: 1
    MaxBatchSize: 1
    WaitOnResourceSignals: true
```
**Benefício:** Updates sem downtime

### **✅ 9. Validação de Parâmetros**
```yaml
InstanceType:
  AllowedValues:
    - t3.micro
    - t3.small
    - t3.medium
```
**Benefício:** Previne erros de configuração

### **🔧 10. Key Pair Opcional**
```yaml
Conditions:
  HasKeyPair: !Not [!Equals [!Ref KeyPairName, ""]]
KeyName: !If [HasKeyPair, !Ref KeyPairName, !Ref "AWS::NoValue"]
```
**Benefício:** Flexibilidade para ambientes sem SSH

---

## 🎯 **PARÂMETROS DO DESAFIO-3 ATENDIDOS**

| **Parâmetro** | **Valor** | **Status** |
|---------------|-----------|------------|
| **Cluster name** | cluster-bia-alb | ✅ |
| **Infrastructure** | Amazon EC2 instances | ✅ |
| **Provisioning model** | On-demand | ✅ |
| **Instance type** | t3.micro | ✅ |
| **EC2 instance role** | role-acesso-ssm | ✅ |
| **Desired capacity** | Min=2, Max=2 | ✅ |
| **VPC** | default | ✅ |
| **Subnets** | us-east-1a, us-east-1b | ✅ |
| **Security group** | bia-ec2 | ✅ |

---

## 🚀 **COMO USAR**

### **Método 1: Script Automatizado (Recomendado)**
```bash
# Deploy completo
./templates/deploy-cluster-melhorado.sh

# Limpeza completa
./templates/cleanup-cluster.sh
```

### **Método 2: AWS CLI Manual**
```bash
# Criar stack
aws cloudformation create-stack \
  --stack-name bia-ecs-cluster-melhorado \
  --template-body file://templates/ecs-cluster-template-melhorado.yaml \
  --parameters \
    ParameterKey=ClusterName,ParameterValue=cluster-bia-alb \
    ParameterKey=InstanceType,ParameterValue=t3.micro \
    ParameterKey=DesiredCapacity,ParameterValue=2 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

# Aguardar criação
aws cloudformation wait stack-create-complete --stack-name bia-ecs-cluster-melhorado
```

### **Método 3: Console AWS**
1. Abrir AWS CloudFormation Console
2. Create Stack → Upload template
3. Selecionar `ecs-cluster-template-melhorado.yaml`
4. Configurar parâmetros conforme DESAFIO-3
5. Create Stack

---

## 📊 **OUTPUTS DISPONÍVEIS**

| **Output** | **Descrição** | **Export Name** |
|------------|---------------|-----------------|
| **ClusterName** | Nome do cluster ECS | `{StackName}-ClusterName` |
| **ClusterArn** | ARN do cluster ECS | `{StackName}-ClusterArn` |
| **CapacityProviderName** | Nome do Capacity Provider | `{StackName}-CapacityProvider` |
| **AutoScalingGroupName** | Nome do Auto Scaling Group | `{StackName}-AutoScalingGroup` |
| **LaunchTemplateId** | ID do Launch Template | `{StackName}-LaunchTemplate` |
| **LogGroupName** | Nome do CloudWatch Log Group | `{StackName}-LogGroup` |

---

## 🔍 **VERIFICAÇÕES DE SUCESSO**

### **1. Stack CloudFormation**
```bash
aws cloudformation describe-stacks --stack-name bia-ecs-cluster-melhorado --query 'Stacks[0].StackStatus'
# Deve retornar: "CREATE_COMPLETE"
```

### **2. Cluster ECS**
```bash
aws ecs describe-clusters --clusters cluster-bia-alb --query 'clusters[0].{Status:status,Instances:registeredContainerInstancesCount}'
# Deve retornar: Status=ACTIVE, Instances=2
```

### **3. Instâncias EC2**
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=ECS Instance - cluster-bia-alb" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId'
# Deve retornar: 2 instance IDs
```

### **4. Auto Scaling Group**
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names cluster-bia-alb-AutoScalingGroup-v2 --query 'AutoScalingGroups[0].{Desired:DesiredCapacity,Running:Instances[?LifecycleState==`InService`] | length(@)}'
# Deve retornar: Desired=2, Running=2
```

---

## ⚠️ **TROUBLESHOOTING**

### **Problema: Stack falha com timeout**
**Causa:** Instâncias não conseguem enviar sinal CloudFormation
**Solução:** 
1. Verificar se role `role-acesso-ssm` tem permissões CloudFormation
2. Verificar conectividade de rede das instâncias
3. Verificar logs das instâncias EC2

### **Problema: AMI não encontrada**
**Causa:** Systems Manager Parameter não acessível
**Solução:**
1. Verificar permissões SSM na role
2. Usar AMI ID específico temporariamente

### **Problema: Instâncias não se registram no cluster**
**Causa:** ECS Agent não consegue se conectar
**Solução:**
1. Verificar Security Groups
2. Verificar User Data das instâncias
3. Verificar logs do ECS Agent

---

## 📈 **PRÓXIMAS MELHORIAS**

### **Planejadas:**
- [ ] **Multi-AZ deployment** com balanceamento automático
- [ ] **Spot Instances** para redução de custos
- [ ] **Custom Metrics** para Auto Scaling
- [ ] **Integration com Secrets Manager**
- [ ] **Blue/Green deployment** support

### **Avançadas:**
- [ ] **Service Discovery** integration
- [ ] **Application Load Balancer** integration
- [ ] **Container Insights** habilitado
- [ ] **X-Ray tracing** support

---

## 🏆 **COMPARAÇÃO COM TEMPLATE ANTERIOR**

| **Aspecto** | **Template Anterior** | **Template Melhorado** |
|-------------|----------------------|------------------------|
| **CloudFormation Signals** | ❌ Não tinha | ✅ Implementado |
| **AMI Management** | ❌ Hardcoded | ✅ Systems Manager |
| **Segurança** | ❌ IMDSv1 | ✅ IMDSv2 obrigatório |
| **Logs** | ❌ Sem logs | ✅ CloudWatch Logs |
| **Tags** | ❌ Básicas | ✅ Padronizadas |
| **Updates** | ❌ Sem policy | ✅ Rolling updates |
| **Validação** | ❌ Sem limites | ✅ Parâmetros validados |
| **Flexibilidade** | ❌ Rígido | ✅ Key Pair opcional |
| **Monitoramento** | ❌ Básico | ✅ Health checks avançados |
| **Documentação** | ❌ Mínima | ✅ Completa |

---

## 📚 **REFERÊNCIAS**

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [CloudFormation Launch Templates](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-launchtemplate.html)
- [Systems Manager Parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [Auto Scaling Groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)
- [ECS Capacity Providers](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html)

---

*Template criado em: 05/08/2025*  
*Baseado em: Documentação oficial AWS + Melhores práticas*  
*Status: Produção - Testado e validado*  
*Compatível com: DESAFIO-3 do projeto BIA*