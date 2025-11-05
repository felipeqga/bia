# 🛡️ GUIA DE RESILIÊNCIA MULTI-REGIÃO AWS

## 📋 **CONTEXTO**

**Data:** 28/01/2025  
**Baseado em:** Experiência real com falha AWS Virgínia (outubro 2024)  
**Problema:** Aplicação com alta disponibilidade (ALB + EC2 + RDS Multi-AZ) ficou fora durante falha regional  
**Solução:** Arquitetura Multi-Região com estratégia Pilot Light  

---

## 🚨 **LIMITAÇÕES DA ALTA DISPONIBILIDADE TRADICIONAL**

### **Multi-AZ ≠ Multi-Região**
| **Proteção** | **Multi-AZ** | **Multi-Região** |
|--------------|---------------|------------------|
| **Falha de datacenter** | ✅ Protege | ✅ Protege |
| **Falha de hardware** | ✅ Protege | ✅ Protege |
| **Falha regional completa** | ❌ Vulnerável | ✅ Protege |
| **Plano de controle AWS** | ❌ Vulnerável | ✅ Protege |

### **Por que a Alta Disponibilidade Falhou:**
- **Plano de Controle Comprometido:** Serviços de gerenciamento da região inoperantes
- **RDS Multi-AZ Preso:** Ambas AZs na mesma região afetada
- **ALB/EC2 Inoperantes:** Dependem do plano de controle regional
- **Dados Inacessíveis:** Sem replicação cross-region

---

## 🎯 **ARQUITETURA PILOT LIGHT (CUSTO OTIMIZADO)**

### **Conceito:**
Manter infraestrutura mínima em região secundária, ativando sob demanda.

### **Distribuição de Recursos:**

#### **🔥 Região Primária (Virgínia - us-east-1):**
```yaml
Status: ATIVO
Recursos:
  - VPC completa com subnets
  - ALB + Target Groups
  - ECS Cluster com instâncias ativas
  - RDS primário (Multi-AZ)
  - Auto Scaling Groups ativos
Custo: 100% (produção normal)
```

#### **💡 Região Secundária (Ohio - us-east-2):**
```yaml
Status: PILOT LIGHT
Recursos:
  - VPC + Security Groups (via IaC)
  - ALB + Target Groups (criados, sem targets)
  - ECS Cluster (0 instâncias)
  - RDS Cross-Region Replica
  - Auto Scaling Groups (desired=0)
Custo: ~15-20% (apenas RDS replica + storage)
```

---

## 🚀 **IMPLEMENTAÇÃO PASSO-A-PASSO**

### **PASSO 1: Preparação da Replicação de Dados**

#### **Opção A: Aurora Global Database (Recomendado)**
```bash
# Criar cluster global
aws rds create-global-cluster \
  --global-cluster-identifier bia-global \
  --source-db-cluster-identifier bia-virginia \
  --engine aurora-mysql

# Adicionar região secundária
aws rds create-db-cluster \
  --db-cluster-identifier bia-ohio \
  --engine aurora-mysql \
  --global-cluster-identifier bia-global \
  --region us-east-2

# Criar instância na região secundária
aws rds create-db-instance \
  --db-instance-identifier bia-ohio-1 \
  --db-cluster-identifier bia-ohio \
  --db-instance-class db.t3.small \
  --engine aurora-mysql \
  --region us-east-2
```

#### **Opção B: Cross-Region Read Replica**
```bash
# Para RDS tradicional (MySQL/PostgreSQL)
aws rds create-db-instance-read-replica \
  --db-instance-identifier bia-ohio-replica \
  --source-db-instance-identifier bia-virginia \
  --db-instance-class db.t3.micro \
  --region us-east-2
```

### **PASSO 2: Infrastructure as Code (IaC)**

#### **Terraform para Ohio (Pilot Light)**
```hcl
# variables.tf
variable "region" {
  default = "us-east-2"
}

variable "desired_capacity" {
  default = 0  # Pilot Light mode
}

# main.tf
provider "aws" {
  region = var.region
}

# VPC e Security Groups
resource "aws_vpc" "bia_ohio" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "bia-ohio-vpc"
    Environment = "pilot-light"
  }
}

# ALB
resource "aws_lb" "bia_ohio" {
  name               = "bia-ohio"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.bia_alb.id]
  subnets           = aws_subnet.public[*].id

  tags = {
    Environment = "pilot-light"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "bia_ohio" {
  name = "cluster-bia-ohio"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Auto Scaling Group (0 instâncias)
resource "aws_autoscaling_group" "bia_ohio" {
  name                = "bia-ohio-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.bia_ohio.arn]
  health_check_type   = "ELB"
  
  min_size         = 0
  max_size         = 4
  desired_capacity = var.desired_capacity  # 0 para Pilot Light
  
  launch_template {
    id      = aws_launch_template.bia_ohio.id
    version = "$Latest"
  }
}
```

### **PASSO 3: CloudFront Origin Failover**

```bash
# Criar distribuição CloudFront com failover
aws cloudfront create-distribution \
  --distribution-config '{
    "CallerReference": "bia-failover-'$(date +%s)'",
    "Comment": "BIA Multi-Region Failover",
    "DefaultCacheBehavior": {
      "TargetOriginId": "primary-virginia",
      "ViewerProtocolPolicy": "redirect-to-https",
      "MinTTL": 0,
      "ForwardedValues": {
        "QueryString": true,
        "Cookies": {"Forward": "all"}
      }
    },
    "Origins": {
      "Quantity": 2,
      "Items": [
        {
          "Id": "primary-virginia",
          "DomainName": "bia-virginia.us-east-1.elb.amazonaws.com",
          "CustomOriginConfig": {
            "HTTPPort": 80,
            "HTTPSPort": 443,
            "OriginProtocolPolicy": "http-only"
          }
        },
        {
          "Id": "failover-ohio", 
          "DomainName": "bia-ohio.us-east-2.elb.amazonaws.com",
          "CustomOriginConfig": {
            "HTTPPort": 80,
            "HTTPSPort": 443,
            "OriginProtocolPolicy": "http-only"
          }
        }
      ]
    },
    "OriginGroups": {
      "Quantity": 1,
      "Items": [
        {
          "Id": "primary-with-failover",
          "FailoverCriteria": {
            "StatusCodes": {
              "Quantity": 3,
              "Items": [403, 404, 500, 502, 503, 504]
            }
          },
          "Members": {
            "Quantity": 2,
            "Items": [
              {"OriginId": "primary-virginia"},
              {"OriginId": "failover-ohio"}
            ]
          }
        }
      ]
    },
    "Enabled": true
  }'
```

---

## ⚡ **PROCESSO DE FAILOVER**

### **Detecção de Falha Regional:**
1. **CloudFront Health Checks** detectam falha na Virgínia
2. **Monitoramento** confirma falha regional (não apenas AZ)
3. **Ativação automática** do Pilot Light em Ohio

### **Ativação do Pilot Light (Automática):**
```bash
#!/bin/bash
# Script de ativação de emergência

# 1. Escalar Auto Scaling Group em Ohio
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name bia-ohio-asg \
  --desired-capacity 2 \
  --region us-east-2

# 2. Promover RDS replica para primário (se necessário)
aws rds promote-read-replica \
  --db-instance-identifier bia-ohio-replica \
  --region us-east-2

# 3. Atualizar Task Definition com novo endpoint DB
aws ecs register-task-definition \
  --cli-input-json file://task-def-ohio.json \
  --region us-east-2

# 4. Criar ECS Service
aws ecs create-service \
  --cluster cluster-bia-ohio \
  --service-name service-bia-ohio \
  --task-definition task-def-bia-ohio \
  --desired-count 2 \
  --region us-east-2

echo "Pilot Light ativado em Ohio!"
```

### **Tempo de Recuperação (RTO):**
- **CloudFront Failover:** 1-3 minutos
- **EC2 Launch:** 3-5 minutos  
- **ECS Service Start:** 2-3 minutos
- **Total:** 6-11 minutos

---

## 💰 **ANÁLISE DE CUSTOS DETALHADA - PROJETO BIA**

### **📊 Configuração BIA Atual:**
- **Endpoint:** `bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com`
- **Engine:** PostgreSQL
- **Classe:** db.t3.micro (projeto educacional)
- **Storage:** 20GB (estimado)
- **Custo atual:** ~$15.71/mês (single region)

### **💵 Cenários de Custos Multi-Região:**

#### **Cenário 1: RDS PostgreSQL + Cross-Region Replica (RECOMENDADO)**
```
Virgínia (Primário):
├── db.t3.micro: $0.017/h × 730h = $12.41/mês
├── Storage 20GB: $0.115/GB × 20 = $2.30/mês
├── Backup Storage: ~$1.00/mês
└── Total Virgínia: $15.71/mês

Ohio (Réplica):
├── db.t3.micro: $0.017/h × 730h = $12.41/mês
├── Storage 20GB: $0.115/GB × 20 = $2.30/mês
├── Data Transfer: $0.02/GB × 5GB = $0.10/mês
└── Total Ohio: $14.81/mês

TOTAL MENSAL: $30.52/mês
OVERHEAD: +$14.81/mês (+94%)
```

#### **Cenário 2: Aurora Global Database**
```
Virgínia (Cluster Primário):
├── db.t3.small: $0.034/h × 730h = $24.82/mês
├── Aurora Storage: $0.10/GB × 20GB = $2.00/mês
├── I/O Requests: ~$1.00/mês
└── Total Virgínia: $27.82/mês

Ohio (Cluster Secundário):
├── db.t3.small: $0.034/h × 730h = $24.82/mês
├── Aurora Storage: $0.10/GB × 20GB = $2.00/mês
├── Cross-Region Replication: $0.20/GB × 5GB = $1.00/mês
└── Total Ohio: $27.82/mês

TOTAL MENSAL: $55.64/mês
OVERHEAD: +$27.82/mês (+254%)
```

### **📈 Comparação Custo-Benefício:**

| **Opção** | **Custo Mensal** | **Overhead** | **RTO** | **RPO** | **Recomendação** |
|-----------|------------------|--------------|---------|---------|------------------|
| **Atual (Single)** | $15.71 | - | ∞ (falha regional) | ∞ | ❌ Vulnerável |
| **RDS Cross-Region** | $30.52 | +94% | 5-15 min | <5 min | ✅ **IDEAL BIA** |
| **Aurora Global** | $55.64 | +254% | 1-3 min | <1 min | ⚠️ Over-engineering |

### **🎯 Recomendação Específica para BIA:**

#### **Solução Otimizada: RDS Cross-Region Replica**
```bash
# Implementação para projeto BIA
aws rds create-db-instance-read-replica \
  --db-instance-identifier bia-ohio-replica \
  --source-db-instance-identifier bia \
  --db-instance-class db.t3.micro \
  --region us-east-2

# Custo adicional: $14.81/mês
# Benefício: Proteção contra falha regional
# ROI: Continuidade do negócio vs $15/mês
```

### **💡 Justificativa da Escolha:**
- **Projeto educacional:** RDS Cross-Region é suficiente
- **Custo controlado:** +$15/mês é razoável para aprendizado
- **Aurora seria over-engineering:** 254% overhead para ganho mínimo
- **KISS Principle:** Simplicidade > complexidade desnecessária

---

## 🔧 **CENÁRIOS DE EMERGÊNCIA**

### **Cenário 1: Sem Replicação Prévia**
```bash
# Última opção: Snapshot recovery
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier bia-snapshot-latest \
  --target-db-snapshot-identifier bia-ohio-restore \
  --source-region us-east-1 \
  --target-region us-east-2

# Restaurar em Ohio (RTO: 30-60 minutos)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier bia-ohio-emergency \
  --db-snapshot-identifier bia-ohio-restore \
  --region us-east-2
```

### **Cenário 2: Rollback Pós-Recuperação**
```bash
# Após Virgínia voltar
# 1. Sincronizar dados Ohio → Virgínia
# 2. Escalar down Ohio para Pilot Light
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name bia-ohio-asg \
  --desired-capacity 0 \
  --region us-east-2

# 3. Reconfigurar CloudFront para Virgínia primária
```

---

## 📊 **MONITORAMENTO E ALERTAS**

### **CloudWatch Alarms:**
```bash
# Alarm para falha regional
aws cloudwatch put-metric-alarm \
  --alarm-name "BIA-Regional-Failure" \
  --alarm-description "Detecta falha regional na Virgínia" \
  --metric-name "HealthyHostCount" \
  --namespace "AWS/ApplicationELB" \
  --statistic "Average" \
  --period 60 \
  --threshold 0 \
  --comparison-operator "LessThanThreshold" \
  --evaluation-periods 3 \
  --alarm-actions "arn:aws:sns:us-east-2:ACCOUNT:bia-failover"
```

### **Testes de Failover:**
```bash
# Teste mensal de failover
# 1. Simular falha na Virgínia
# 2. Verificar ativação automática Ohio
# 3. Testar aplicação via CloudFront
# 4. Rollback para Virgínia
```

---

## 🎯 **CONCLUSÕES**

### **✅ Benefícios:**
- **Resiliência completa:** Protege contra falhas regionais
- **Custo otimizado:** Pilot Light vs Active/Active
- **RTO baixo:** 6-11 minutos para recuperação
- **Automação:** Failover sem intervenção manual

### **⚠️ Considerações:**
- **Complexidade:** Requer IaC e automação
- **Custo adicional:** ~65% overhead
- **Testes regulares:** Essencial para validar funcionamento
- **Sincronização de dados:** Crítica para consistência

### **🚀 Próximos Passos:**
1. Implementar Aurora Global Database
2. Criar IaC para Ohio (Pilot Light)
3. Configurar CloudFront Origin Failover
4. Estabelecer testes mensais de failover
5. Documentar runbooks de emergência

---

**A resiliência multi-região é o próximo nível de maturidade arquitetural. O investimento em Pilot Light oferece proteção máxima com custo controlado.** 🛡️

---

*Criado em: 28/01/2025*  
*Baseado em: Experiência real com falha AWS Virgínia*  
*Validado por: Análise técnica completa de custos e benefícios*
