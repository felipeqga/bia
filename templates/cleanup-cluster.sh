#!/bin/bash

# 🗑️ Script de Limpeza Completa - Cluster ECS
# Remove todos os recursos relacionados ao cluster

set -e

# Configurações
STACK_NAME="bia-ecs-cluster-melhorado"
CLUSTER_NAME="cluster-bia-alb"
REGION="us-east-1"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

log "🗑️ Iniciando limpeza completa do cluster ECS"

# 1. Deletar stack CloudFormation
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" >/dev/null 2>&1; then
    log "Deletando stack CloudFormation: $STACK_NAME"
    aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
    
    log "⏳ Aguardando deleção da stack..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"
    log "✅ Stack deletada com sucesso!"
else
    warn "Stack $STACK_NAME não encontrada"
fi

# 2. Verificar se cluster ECS ainda existe
if aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
    CLUSTER_STATUS=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" --query 'clusters[0].status' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ "$CLUSTER_STATUS" != "NOT_FOUND" && "$CLUSTER_STATUS" != "INACTIVE" ]]; then
        log "Deletando cluster ECS órfão: $CLUSTER_NAME"
        aws ecs delete-cluster --cluster "$CLUSTER_NAME" --region "$REGION"
        log "✅ Cluster ECS deletado!"
    fi
fi

# 3. Verificar instâncias EC2 órfãs
log "🔍 Verificando instâncias EC2 órfãs..."
ORPHAN_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=ECS Instance - $CLUSTER_NAME" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*].InstanceId' --output text 2>/dev/null || echo "")

if [[ -n "$ORPHAN_INSTANCES" && "$ORPHAN_INSTANCES" != "None" ]]; then
    warn "Encontradas instâncias órfãs: $ORPHAN_INSTANCES"
    log "Terminando instâncias órfãs..."
    aws ec2 terminate-instances --instance-ids $ORPHAN_INSTANCES --region "$REGION"
    log "✅ Instâncias órfãs terminadas!"
else
    log "✅ Nenhuma instância órfã encontrada"
fi

# 4. Verificar Launch Templates órfãos
log "🔍 Verificando Launch Templates órfãos..."
ORPHAN_TEMPLATES=$(aws ec2 describe-launch-templates \
    --filters "Name=launch-template-name,Values=*cluster-bia-alb*" \
    --region "$REGION" \
    --query 'LaunchTemplates[*].LaunchTemplateId' --output text 2>/dev/null || echo "")

if [[ -n "$ORPHAN_TEMPLATES" && "$ORPHAN_TEMPLATES" != "None" ]]; then
    warn "Encontrados Launch Templates órfãos: $ORPHAN_TEMPLATES"
    for template_id in $ORPHAN_TEMPLATES; do
        log "Deletando Launch Template: $template_id"
        aws ec2 delete-launch-template --launch-template-id "$template_id" --region "$REGION" 2>/dev/null || warn "Falha ao deletar $template_id"
    done
    log "✅ Launch Templates órfãos removidos!"
else
    log "✅ Nenhum Launch Template órfão encontrado"
fi

# 5. Verificar Auto Scaling Groups órfãos
log "🔍 Verificando Auto Scaling Groups órfãos..."
ORPHAN_ASGS=$(aws autoscaling describe-auto-scaling-groups \
    --region "$REGION" \
    --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'cluster-bia-alb')].AutoScalingGroupName" --output text 2>/dev/null || echo "")

if [[ -n "$ORPHAN_ASGS" && "$ORPHAN_ASGS" != "None" ]]; then
    warn "Encontrados Auto Scaling Groups órfãos: $ORPHAN_ASGS"
    for asg_name in $ORPHAN_ASGS; do
        log "Deletando Auto Scaling Group: $asg_name"
        # Primeiro zerar desired capacity
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg_name" --desired-capacity 0 --min-size 0 --region "$REGION" 2>/dev/null || warn "Falha ao atualizar $asg_name"
        sleep 10
        # Depois deletar
        aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$asg_name" --force-delete --region "$REGION" 2>/dev/null || warn "Falha ao deletar $asg_name"
    done
    log "✅ Auto Scaling Groups órfãos removidos!"
else
    log "✅ Nenhum Auto Scaling Group órfão encontrado"
fi

# 6. Verificar Capacity Providers órfãos
log "🔍 Verificando Capacity Providers órfãos..."
ORPHAN_CPS=$(aws ecs describe-capacity-providers \
    --region "$REGION" \
    --query "capacityProviders[?contains(name, 'bia-ecs-cluster') || contains(name, 'cluster-bia')].name" --output text 2>/dev/null || echo "")

if [[ -n "$ORPHAN_CPS" && "$ORPHAN_CPS" != "None" ]]; then
    warn "Encontrados Capacity Providers órfãos: $ORPHAN_CPS"
    for cp_name in $ORPHAN_CPS; do
        log "Deletando Capacity Provider: $cp_name"
        aws ecs delete-capacity-provider --capacity-provider "$cp_name" --region "$REGION" 2>/dev/null || warn "Falha ao deletar $cp_name"
    done
    log "✅ Capacity Providers órfãos removidos!"
else
    log "✅ Nenhum Capacity Provider órfão encontrado"
fi

# 7. Verificação final
log "🔍 Verificação final..."

# Clusters ECS
REMAINING_CLUSTERS=$(aws ecs list-clusters --region "$REGION" --query 'clusterArns' --output text 2>/dev/null || echo "")
if [[ -z "$REMAINING_CLUSTERS" || "$REMAINING_CLUSTERS" == "None" ]]; then
    log "✅ Nenhum cluster ECS ativo"
else
    warn "Clusters ECS ainda ativos: $REMAINING_CLUSTERS"
fi

# Instâncias EC2
REMAINING_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=ECS Instance - $CLUSTER_NAME" "Name=instance-state-name,Values=running,pending" \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*].InstanceId' --output text 2>/dev/null || echo "")

if [[ -z "$REMAINING_INSTANCES" || "$REMAINING_INSTANCES" == "None" ]]; then
    log "✅ Nenhuma instância EC2 ativa"
else
    warn "Instâncias EC2 ainda ativas: $REMAINING_INSTANCES"
fi

log "🎉 Limpeza completa finalizada!"
log "💡 Ambiente limpo e pronto para nova criação"