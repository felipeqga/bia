# Troubleshooting - Projeto BIA

## Problemas Comuns e Soluções

### 1. DNS do ALB mudou
**Sintoma:** Aplicação não responde no DNS documentado
**Causa:** ALB foi recriado ou DNS foi alterado

**Solução:**
```bash
# Verificar DNS atual do ALB
aws elbv2 describe-load-balancers --names bia --query 'LoadBalancers[0].DNSName' --output text

# Atualizar Dockerfile com novo DNS (se necessário)
# Rebuild e push da imagem Docker
```

### 2. Otimizações de Performance Perdidas
**Sintoma:** Deploy muito lento (mais de 5 minutos)
**Causa:** Configurações de otimização foram resetadas

**Verificação:**
```bash
# Verificar Target Group (deve ser 10s)
aws elbv2 describe-target-groups --names tg-bia --query 'TargetGroups[0].HealthCheckIntervalSeconds'

# Verificar ECS Service (deve ser 200%)
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --query 'services[0].deploymentConfiguration.maximumPercent'
```

**Solução:**
```bash
# Reaplicar otimizações
aws elbv2 modify-target-group \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/9e999191b3d60e38 \
  --health-check-interval-seconds 10

aws ecs update-service --cluster cluster-bia-alb --service service-bia-alb \
  --deployment-configuration maximumPercent=200,minimumHealthyPercent=50
```

### 3. Aplicação não conecta ao banco após CodePipeline
**Sintoma:** 
- `/api/versao` funciona (retorna "Bia 4.2.0")
- `/api/usuarios` retorna HTML em vez de JSON

**Causa:** CodePipeline não preserva variáveis de ambiente do banco

**Solução:**
```bash
# Configurar variáveis no CodeBuild
aws codebuild update-project --name bia-build-pipeline --environment '{
  "type": "LINUX_CONTAINER",
  "image": "aws/codebuild/amazonlinux2-x86_64-standard:3.0",
  "computeType": "BUILD_GENERAL1_MEDIUM",
  "environmentVariables": [
    {"name": "DB_HOST", "value": "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"},
    {"name": "DB_USER", "value": "postgres"},
    {"name": "DB_PWD", "value": "Kgegwlaj6mAIxzHaEqgo"},
    {"name": "DB_PORT", "value": "5432"}
  ]
}'
```

### 4. ECR Login falha no CodeBuild
**Sintoma:** `aws ecr get-login-password` retorna erro de permissão

**Solução:**
```bash
# Adicionar policy à role do CodeBuild
aws iam attach-role-policy \
  --role-name codebuild-bia-build-pipeline-service-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### 5. Service ECS não inicia tasks
**Sintoma:** `desiredCount: 2` mas `runningCount: 0`

**Verificação:**
```bash
# Verificar eventos do service
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --query 'services[0].events[0:5]'

# Verificar instâncias EC2 do cluster
aws ecs describe-container-instances --cluster cluster-bia-alb
```

**Possíveis causas:**
- Instâncias EC2 não registradas no cluster
- Recursos insuficientes (CPU/Memory)
- Problemas de conectividade com ECR

### 6. Target Group Unhealthy
**Sintoma:** Tasks rodando mas Target Group mostra "unhealthy"

**Verificação:**
```bash
# Verificar health do target group
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/9e999191b3d60e38
```

**Soluções:**
- Verificar se aplicação responde na porta 8080
- Confirmar health check path: `/api/versao`
- Verificar Security Groups (bia-alb → bia-ec2)

### 7. CodePipeline falha no Deploy
**Sintoma:** Build passa mas deploy falha

**Verificação:**
```bash
# Verificar logs do CodePipeline
aws codepipeline get-pipeline-execution --pipeline-name bia --pipeline-execution-id <execution-id>
```

**Possíveis causas:**
- Service ECS não existe
- Permissões insuficientes
- Task Definition inválida

---

## Comandos de Diagnóstico Rápido

### Status Geral da Infraestrutura
```bash
# ECS Service
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Target Group Health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:387678648422:targetgroup/tg-bia/9e999191b3d60e38 --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}'

# Teste da aplicação
curl -s http://bia-1429815790.us-east-1.elb.amazonaws.com/api/versao
```

### Logs Importantes
```bash
# Logs do ECS Service
aws logs describe-log-groups --log-group-name-prefix "/ecs/task-def-bia-alb"

# Logs do CodeBuild
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/bia-build-pipeline"
```

---

## 🚀 **PROBLEMA: Erros no CodePipeline**

### **Problema 1: Erro de Policy Durante Criação**
**Sintoma:** Erro de policy conflitante ao criar pipeline
**Solução:** Deletar policy com nome que aparece no erro
```bash
aws iam delete-policy --policy-arn arn:aws:iam::ACCOUNT:policy/NOME-DA-POLICY
```

### **Problema 2: ECR Login Falha no CodeBuild**
**Sintoma:** 
```
Error while executing command: aws ecr get-login-password
Reason: exit status 1
```
**Solução:** Adicionar permissão ECR à role do CodeBuild
```bash
aws iam attach-role-policy \
  --role-name codebuild-bia-build-pipeline-service-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### **Problema 3: PassRole Error**
**Sintoma:** `AccessDenied: iam:PassRole`
**Solução:** Criar policy PASSROLE inline na role do CodeBuild

**Documentação completa:** `.amazonq/context/codepipeline-troubleshooting-permissions.md`

---

## 🔐 **PROBLEMA: Permissões Insuficientes para Análise**

### **Sintomas:**
- `AccessDenied: route53:ListHostedZones`
- `AccessDenied: acm:ListCertificates`
- `AccessDenied: codepipeline:ListPipelines`
- `AccessDenied: codebuild:ListProjects`

### **Causa:**
Role `role-acesso-ssm` não tem permissões para todos os serviços do DESAFIO-3

### **✅ SOLUÇÃO AUTOMÁTICA:**
Amazon Q resolve automaticamente se a role tiver `iam:*`:

```bash
# Para Route 53 + ACM
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name Route53_ACM_Access \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["route53:*", "acm:*", "cloudformation:*"],
      "Resource": "*"
    }]
  }'

# Para CodePipeline + CodeBuild
aws iam put-role-policy \
  --role-name role-acesso-ssm \
  --policy-name CodePipeline_CodeBuild_Access \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["codepipeline:*", "codebuild:*"],
      "Resource": "*"
    }]
  }'
```

### **🔍 VERIFICAÇÃO:**
```bash
# Testar permissões
aws route53 list-hosted-zones
aws acm list-certificates
aws codepipeline list-pipelines
aws codebuild list-projects
```

### **📋 PRÉ-REQUISITO:**
**A role DEVE ter `iam:*` para auto-correção funcionar!**

**Documentação completa:** `.amazonq/context/permissoes-completas-desafio-3.md`

---

*Baseado em problemas reais encontrados durante implementação*
*Atualizado com soluções testadas e validadas*
*Permissões extras documentadas: Route 53, ACM, CodePipeline, CodeBuild*
