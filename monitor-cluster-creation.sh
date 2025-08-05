#!/bin/bash

# Script de Monitoramento em Tempo Real - Criação Cluster ECS via Console AWS
# Projeto BIA - Capturar template CloudFormation interno

REGION="us-east-1"
CLUSTER_NAME="cluster-bia-alb"
LOG_FILE="/home/ec2-user/bia/cluster-creation-monitor.log"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}" | tee -a $LOG_FILE
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}" | tee -a $LOG_FILE
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] $1${NC}" | tee -a $LOG_FILE
}

# Função para monitorar CloudFormation
monitor_cloudformation() {
    echo "=== CLOUDFORMATION STACKS ===" >> $LOG_FILE
    aws cloudformation describe-stacks --region $REGION --query 'Stacks[?contains(StackName, `cluster-bia-alb`) || contains(StackName, `Infra-ECS-Cluster`)].{Name:StackName,Status:StackStatus,Created:CreationTime}' --output table >> $LOG_FILE 2>/dev/null
    
    # Capturar detalhes do stack se existir
    STACK_NAME=$(aws cloudformation describe-stacks --region $REGION --query 'Stacks[?contains(StackName, `Infra-ECS-Cluster-cluster-bia-alb`)].StackName' --output text 2>/dev/null)
    if [ -n "$STACK_NAME" ] && [ "$STACK_NAME" != "None" ]; then
        echo "=== STACK RESOURCES: $STACK_NAME ===" >> $LOG_FILE
        aws cloudformation describe-stack-resources --stack-name "$STACK_NAME" --region $REGION >> $LOG_FILE 2>/dev/null
        
        echo "=== STACK TEMPLATE: $STACK_NAME ===" >> $LOG_FILE
        aws cloudformation get-template --stack-name "$STACK_NAME" --region $REGION >> $LOG_FILE 2>/dev/null
    fi
}

# Função para monitorar Auto Scaling Groups
monitor_asg() {
    echo "=== AUTO SCALING GROUPS ===" >> $LOG_FILE
    aws autoscaling describe-auto-scaling-groups --region $REGION --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `cluster-bia-alb`) || contains(Tags[?Key==`aws:cloudformation:stack-name`].Value, `Infra-ECS-Cluster`)].{Name:AutoScalingGroupName,Status:Status,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:length(Instances)}' --output table >> $LOG_FILE 2>/dev/null
}

# Função para monitorar Launch Templates
monitor_launch_templates() {
    echo "=== LAUNCH TEMPLATES ===" >> $LOG_FILE
    aws ec2 describe-launch-templates --region $REGION --query 'LaunchTemplates[?contains(LaunchTemplateName, `cluster-bia-alb`) || contains(LaunchTemplateName, `ECS`)].{Name:LaunchTemplateName,Id:LaunchTemplateId,Version:LatestVersionNumber,Created:CreateTime}' --output table >> $LOG_FILE 2>/dev/null
    
    # Capturar detalhes do Launch Template se existir
    LT_ID=$(aws ec2 describe-launch-templates --region $REGION --query 'LaunchTemplates[?contains(LaunchTemplateName, `ECSLaunchTemplate`)].LaunchTemplateId' --output text 2>/dev/null)
    if [ -n "$LT_ID" ] && [ "$LT_ID" != "None" ]; then
        echo "=== LAUNCH TEMPLATE DETAILS: $LT_ID ===" >> $LOG_FILE
        aws ec2 describe-launch-template-versions --launch-template-id "$LT_ID" --region $REGION >> $LOG_FILE 2>/dev/null
    fi
}

# Função para monitorar Capacity Providers
monitor_capacity_providers() {
    echo "=== CAPACITY PROVIDERS ===" >> $LOG_FILE
    aws ecs describe-capacity-providers --region $REGION --query 'capacityProviders[?contains(name, `cluster-bia-alb`) || contains(name, `Infra-ECS`)].{Name:name,Status:status,ASG:autoScalingGroupProvider.autoScalingGroupArn}' --output table >> $LOG_FILE 2>/dev/null
}

# Função para monitorar ECS Cluster
monitor_ecs_cluster() {
    echo "=== ECS CLUSTER ===" >> $LOG_FILE
    aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --include ATTACHMENTS --query 'clusters[0].{Name:clusterName,Status:status,Instances:registeredContainerInstancesCount,CapacityProviders:capacityProviders,Attachments:attachments}' --output table >> $LOG_FILE 2>/dev/null
    
    # Listar container instances se existirem
    INSTANCES=$(aws ecs list-container-instances --cluster $CLUSTER_NAME --region $REGION --query 'containerInstanceArns' --output text 2>/dev/null)
    if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
        echo "=== CONTAINER INSTANCES ===" >> $LOG_FILE
        aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $INSTANCES --region $REGION >> $LOG_FILE 2>/dev/null
    fi
}

# Função para monitorar EC2 Instances
monitor_ec2_instances() {
    echo "=== EC2 INSTANCES (ECS) ===" >> $LOG_FILE
    aws ec2 describe-instances --region $REGION --filters "Name=tag:aws:autoscaling:groupName,Values=*cluster-bia-alb*" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType,LaunchTime:LaunchTime,Tags:Tags[?Key==`Name`].Value|[0]}' --output table >> $LOG_FILE 2>/dev/null
}

# Loop principal de monitoramento
main() {
    log "🚀 INICIANDO MONITORAMENTO - Criação Cluster ECS via Console AWS"
    log "📝 Log salvo em: $LOG_FILE"
    log "⏰ Monitoramento a cada 10 segundos..."
    
    > $LOG_FILE  # Limpar log anterior
    
    ITERATION=0
    while true; do
        ITERATION=$((ITERATION + 1))
        
        echo "" >> $LOG_FILE
        echo "==================== ITERATION $ITERATION - $(date) ====================" >> $LOG_FILE
        
        info "Iteration $ITERATION - Capturando recursos..."
        
        monitor_cloudformation
        monitor_asg
        monitor_launch_templates
        monitor_capacity_providers
        monitor_ecs_cluster
        monitor_ec2_instances
        
        echo "==================== END ITERATION $ITERATION ====================" >> $LOG_FILE
        
        # Verificar se cluster está ativo com instâncias
        CLUSTER_STATUS=$(aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query 'clusters[0].status' --output text 2>/dev/null)
        INSTANCE_COUNT=$(aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query 'clusters[0].registeredContainerInstancesCount' --output text 2>/dev/null)
        
        if [ "$CLUSTER_STATUS" = "ACTIVE" ] && [ "$INSTANCE_COUNT" -gt 0 ]; then
            log "✅ CLUSTER ATIVO COM $INSTANCE_COUNT INSTÂNCIAS - Captura completa!"
            break
        fi
        
        sleep 10
    done
    
    log "🎯 MONITORAMENTO CONCLUÍDO - Recursos capturados em $LOG_FILE"
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
