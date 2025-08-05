#!/bin/bash

# Script para Deletar Cluster ECS e Recursos Relacionados - Projeto BIA
# Baseado na experiência de deleção manual realizada

set -e

CLUSTER_NAME="cluster-bia-alb"
REGION="us-east-1"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Função para verificar se cluster existe
check_cluster_exists() {
    aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query 'clusters[0].status' --output text 2>/dev/null || echo "NOT_FOUND"
}

# Função para desregistrar container instances
deregister_container_instances() {
    log "🔍 Verificando container instances..."
    
    INSTANCES=$(aws ecs list-container-instances --cluster $CLUSTER_NAME --region $REGION --query 'containerInstanceArns' --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
        log "📋 Desregistrando container instances..."
        for instance in $INSTANCES; do
            instance_id=$(basename $instance)
            info "Desregistrando instância: $instance_id"
            aws ecs deregister-container-instance --cluster $CLUSTER_NAME --container-instance $instance_id --region $REGION
        done
        
        # Obter IDs das instâncias EC2 para terminar
        log "🔍 Obtendo IDs das instâncias EC2..."
        EC2_INSTANCES=$(aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $INSTANCES --region $REGION --query 'containerInstances[].ec2InstanceId' --output text 2>/dev/null || echo "")
        
        if [ -n "$EC2_INSTANCES" ] && [ "$EC2_INSTANCES" != "None" ]; then
            log "🛑 Terminando instâncias EC2..."
            aws ec2 terminate-instances --instance-ids $EC2_INSTANCES --region $REGION
            info "Instâncias EC2 terminadas: $EC2_INSTANCES"
        fi
    else
        info "Nenhuma container instance encontrada"
    fi
}

# Função para deletar Auto Scaling Group
delete_auto_scaling_group() {
    log "🔍 Verificando Auto Scaling Groups..."
    
    ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --region $REGION --query "AutoScalingGroups[?contains(AutoScalingGroupName, '$CLUSTER_NAME') || contains(Tags[?Key=='aws:cloudformation:stack-name'].Value, 'Infra-ECS-Cluster-$CLUSTER_NAME')].AutoScalingGroupName" --output text 2>/dev/null || echo "")
    
    if [ -n "$ASG_NAME" ] && [ "$ASG_NAME" != "None" ]; then
        log "🗑️ Deletando Auto Scaling Group: $ASG_NAME"
        aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" --force-delete --region $REGION
        info "Auto Scaling Group deletado"
    else
        info "Nenhum Auto Scaling Group encontrado"
    fi
}

# Função para deletar CloudFormation Stack
delete_cloudformation_stack() {
    log "🔍 Verificando CloudFormation Stacks..."
    
    STACK_NAME=$(aws cloudformation describe-stacks --region $REGION --query "Stacks[?contains(StackName, 'Infra-ECS-Cluster-$CLUSTER_NAME')].StackName" --output text 2>/dev/null || echo "")
    
    if [ -n "$STACK_NAME" ] && [ "$STACK_NAME" != "None" ]; then
        log "🗑️ Deletando CloudFormation Stack: $STACK_NAME"
        aws cloudformation delete-stack --stack-name "$STACK_NAME" --region $REGION
        info "CloudFormation Stack deletado"
    else
        info "Nenhum CloudFormation Stack encontrado"
    fi
}

# Função para deletar cluster ECS
delete_ecs_cluster() {
    log "🔍 Verificando status do cluster..."
    
    CLUSTER_STATUS=$(check_cluster_exists)
    
    if [ "$CLUSTER_STATUS" != "NOT_FOUND" ] && [ "$CLUSTER_STATUS" != "None" ]; then
        log "⏳ Aguardando attachments serem atualizados..."
        sleep 30
        
        log "🗑️ Deletando cluster ECS: $CLUSTER_NAME"
        aws ecs delete-cluster --cluster $CLUSTER_NAME --region $REGION
        info "Cluster ECS deletado"
    else
        info "Cluster não encontrado ou já deletado"
    fi
}

# Função principal
main() {
    log "🚀 Iniciando deleção do cluster ECS: $CLUSTER_NAME"
    
    # Verificar se cluster existe
    CLUSTER_STATUS=$(check_cluster_exists)
    if [ "$CLUSTER_STATUS" == "NOT_FOUND" ]; then
        warn "Cluster $CLUSTER_NAME não encontrado"
        exit 0
    fi
    
    # Passo 1: Desregistrar container instances e terminar EC2
    deregister_container_instances
    
    # Passo 2: Deletar Auto Scaling Group
    delete_auto_scaling_group
    
    # Passo 3: Deletar CloudFormation Stack
    delete_cloudformation_stack
    
    # Passo 4: Deletar cluster ECS
    delete_ecs_cluster
    
    log "✅ Deleção completa do cluster $CLUSTER_NAME finalizada!"
    info "Recursos deletados:"
    info "  - Container instances desregistradas"
    info "  - Instâncias EC2 terminadas"
    info "  - Auto Scaling Group deletado"
    info "  - CloudFormation Stack deletado"
    info "  - Cluster ECS deletado"
}

# Verificar se é execução direta
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi