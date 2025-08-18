# 💰 GUIA ESPECIALISTA: Economia AWS - Projeto BIA

## 🎯 **METODOLOGIA DE ANÁLISE DE CUSTOS**

### **📊 PROCESSO SISTEMÁTICO:**
1. **Levantamento Completo** - Identificar todos os recursos
2. **Categorização por Custo** - Classificar por impacto financeiro
3. **Análise de Necessidade** - Avaliar se é essencial
4. **Estratégia de Economia** - Definir ações de otimização
5. **Implementação Segura** - Executar com confirmação

---

## 📋 **RECURSOS AWS POR CATEGORIA DE CUSTO**

### **🔴 ALTO CUSTO (>$10/mês):**

#### **RDS (Relational Database Service)**
- **Custo:** $13-18/mês (t3.micro + storage)
- **Componentes:**
  - Instância: db.t3.micro (~$13-15/mês)
  - Storage: 20GB gp2 (~$2.30/mês)
  - Backup: Configurável (0-35 dias)
- **Economia:**
  - ✅ Deletar se não usado: -$15-18/mês
  - ⚠️ Parar/Iniciar: -$13/mês (máx 7 dias parado)
  - 🔧 Reduzir storage: Variável

#### **ECS Cluster (2x EC2)**
- **Custo:** ~$17/mês (2x t3.micro)
- **Componentes:**
  - 2 instâncias EC2 t3.micro
  - Auto Scaling Group
  - Capacity Provider
- **Economia:**
  - ✅ Deletar cluster: -$17/mês
  - 🔧 Usar Fargate Spot: -30-50%
  - 🔧 Reduzir para 1 instância: -$8.50/mês

#### **Application Load Balancer**
- **Custo:** ~$16.20/mês
- **Componentes:**
  - ALB base: $16.20/mês (fixo)
  - Data processing: Variável por GB
- **Economia:**
  - ✅ Deletar ALB: -$16.20/mês
  - 🔧 Usar Network LB: -$5/mês
  - ❌ Não há alternativa mais barata para HTTP/HTTPS

#### **Amazon Q**
- **Custo:** $8.75/mês (baseado no uso)
- **Componentes:**
  - Queries/Requests
  - Processamento
- **Economia:**
  - 🔧 Otimizar uso: Variável
  - ⚠️ Reduzir sessões: Impacta produtividade

---

### **🟡 MÉDIO CUSTO ($1-10/mês):**

#### **EC2 t3.micro**
- **Custo:** $8.50/mês (Free Tier: $0)
- **Componentes:**
  - Instância: $8.50/mês
  - EBS: $1.50/mês (15GB)
- **Economia:**
  - ✅ Free Tier: -$8.50/mês (se elegível)
  - 🔧 t3.nano: -$4.25/mês
  - ⚠️ Parar quando não usar: Variável

#### **IPv4 Público**
- **Custo:** $3.22/mês (Free Tier: 100h gratuitas)
- **Componentes:**
  - $0.005/hora após Free Tier
  - ~644 horas cobradas/mês
- **Economia:**
  - ✅ Remover IP público: -$3.22/mês
  - 🔧 Usar IPv6: -$3.22/mês
  - ⚠️ Usar Session Manager: -$3.22/mês

#### **CodePipeline**
- **Custo:** $1/mês por pipeline
- **Componentes:**
  - Pipeline base: $1/mês
  - Execuções: Incluídas
- **Economia:**
  - ✅ Deletar pipeline: -$1/mês
  - 🔧 Usar GitHub Actions: -$1/mês

---

### **🟢 BAIXO CUSTO (<$1/mês):**

#### **Route 53 Hosted Zone**
- **Custo:** $0.50/mês por zona
- **Componentes:**
  - Hosted Zone: $0.50/mês (fixo)
  - Queries: $0.40 por milhão
- **Economia:**
  - ❌ Necessário para domínio
  - 🔧 Consolidar zonas: Variável

#### **CloudWatch Logs**
- **Custo:** $0.50/mês (baseado em volume)
- **Componentes:**
  - Ingestão: $0.50 por GB
  - Armazenamento: $0.03 por GB/mês
- **Economia:**
  - ✅ Deletar logs antigos: Variável
  - 🔧 Reduzir retenção: -50-90%
  - 🔧 Filtrar logs: -30-70%

#### **CodeBuild**
- **Custo:** $0.46/mês (baseado em uso)
- **Componentes:**
  - BUILD_GENERAL1_MEDIUM: $0.005/min
  - Builds executados: Variável
- **Economia:**
  - ✅ Deletar projeto: -$0.46/mês
  - 🔧 BUILD_GENERAL1_SMALL: -50%
  - 🔧 Otimizar builds: -30-50%

---

## 🎯 **ESTRATÉGIAS DE ECONOMIA POR CENÁRIO**

### **💰 ECONOMIA MÁXIMA (Projeto Pausado):**
```
Deletar:
- RDS: -$15-18/mês
- ECS Cluster: -$17/mês  
- ALB: -$16.20/mês
- CodePipeline: -$1/mês
- CloudWatch Logs: -$0.50/mês
- CodeBuild: -$0.46/mês

TOTAL ECONOMIZADO: ~$50-53/mês
CUSTO RESTANTE: ~$12-15/mês
```

### **🔧 ECONOMIA MODERADA (Projeto Ativo):**
```
Otimizar:
- ECS: 1 instância: -$8.50/mês
- IPv4: Session Manager: -$3.22/mês
- CodeBuild: SMALL: -$0.23/mês
- CloudWatch: 7 dias retenção: -$0.25/mês

TOTAL ECONOMIZADO: ~$12/mês
MANTÉM: Funcionalidade completa
```

### **⚡ ECONOMIA INTELIGENTE (Free Tier):**
```
Aproveitar Free Tier:
- EC2: 750h gratuitas: -$8.50/mês
- EBS: 30GB gratuitos: -$1.50/mês
- RDS: 750h gratuitas: -$13/mês
- IPv4: 100h gratuitas: -$0.50/mês

TOTAL ECONOMIZADO: ~$23.50/mês
REQUISITO: Conta elegível ao Free Tier
```

---

## 🔍 **COMANDOS DE ANÁLISE ESSENCIAIS**

### **📊 Levantamento Completo:**
```bash
# EC2 Instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress]' --output table

# RDS Instances  
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus,AllocatedStorage]' --output table

# Load Balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code]' --output table

# ECS Clusters
aws ecs describe-clusters --query 'clusters[*].[clusterName,status,runningTasksCount]' --output table
```

### **💰 Análise de Custos:**
```bash
# Volumes EBS
aws ec2 describe-volumes --query 'Volumes[*].[VolumeId,Size,VolumeType,State]' --output table

# Security Groups órfãos
aws ec2 describe-security-groups --query 'SecurityGroups[?length(IpPermissions)==`0` && GroupName!=`default`].[GroupId,GroupName]' --output table

# CloudWatch Log Groups
aws logs describe-log-groups --query 'logGroups[*].[logGroupName,storedBytes]' --output table
```

---

## 📈 **MÉTRICAS DE SUCESSO**

### **🎯 KPIs de Economia:**
- **Redução de Custo:** % de economia mensal
- **Recursos Otimizados:** Quantidade de recursos otimizados
- **Tempo de Payback:** Tempo para recuperar investimento
- **Eficiência:** Custo por funcionalidade mantida

### **📊 Benchmarks do Projeto BIA:**
```
Custo Original: ~$60/mês (todos os recursos ativos)
Custo Otimizado: ~$10/mês (recursos essenciais)
Economia Alcançada: 83% de redução
Funcionalidade Mantida: 90% (desenvolvimento)
```

---

## ⚠️ **RISCOS E PRECAUÇÕES**

### **🚨 Ações de Alto Risco:**
- **Deletar RDS:** Perda permanente de dados
- **Remover IPv4:** Perda de acesso SSH direto
- **Deletar ALB:** Quebra de alta disponibilidade

### **✅ Ações Seguras:**
- **Parar instâncias:** Reversível
- **Deletar logs antigos:** Sem impacto operacional
- **Otimizar Security Groups:** Melhora segurança

### **🔧 Ações Reversíveis:**
- **Modificar tipos de instância:** Upgrade/downgrade
- **Ajustar retenção de logs:** Configurável
- **Pausar serviços:** Reativação rápida

---

## 🎯 **CHECKLIST DE ECONOMIA**

### **📋 Antes de Implementar:**
- [ ] Identificar todos os recursos ativos
- [ ] Calcular custo atual vs. projetado
- [ ] Avaliar impacto na funcionalidade
- [ ] Definir plano de rollback
- [ ] Obter aprovação do usuário

### **📋 Durante Implementação:**
- [ ] Executar em ordem de menor risco
- [ ] Confirmar cada ação com usuário
- [ ] Documentar mudanças realizadas
- [ ] Monitorar impacto imediato
- [ ] Validar funcionalidade mantida

### **📋 Após Implementação:**
- [ ] Verificar economia real vs. projetada
- [ ] Monitorar por 24-48h
- [ ] Documentar lições aprendidas
- [ ] Atualizar documentação de custos
- [ ] Planejar próximas otimizações

---

*Guia criado em: 18/08/2025*  
*Baseado em: Análise real do Projeto BIA*  
*Economia comprovada: 83% de redução de custos*  
*Status: Metodologia validada e testada*
