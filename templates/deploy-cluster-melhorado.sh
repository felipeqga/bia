#!/bin/bash

# 🚀 Script de Deploy do Cluster ECS Melhorado - DESAFIO-3
# Baseado na documentação oficial AWS com melhores práticas

set -e  # Parar em caso de erro

# Configurações
STACK_NAME="bia-ecs-cluster-melhorado"
TEMPLATE_FILE="templates/ecs-cluster-template-melhorado.yaml"
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
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

# Verificar se template existe
if [ ! -f "$TEMPLATE_FILE" ]; then
    error "Template não encontrado: $TEMPLATE_FILE"
    exit 1
fi

log "🚀 Iniciando deploy do Cluster ECS Melhorado"
info "Stack: $STACK_NAME"
info "Template: $TEMPLATE_FILE"
info "Região: $REGION"

# Verificar se stack já existe
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" >/dev/null 2>&1; then
    warn "Stack $STACK_NAME já existe. Atualizando..."
    
    # Update stack
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=ClusterName,ParameterValue=cluster-bia-alb \
            ParameterKey=InstanceType,ParameterValue=t3.micro \
            ParameterKey=MinSize,ParameterValue=2 \
            ParameterKey=MaxSize,ParameterValue=2 \
            ParameterKey=DesiredCapacity,ParameterValue=2 \
            ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
            ParameterKey=SubnetIds,ParameterValue="subnet-068e3484d05611445,subnet-0c665b052ff5c528d" \
            ParameterKey=SecurityGroupId,ParameterValue=sg-00c1a082f04bc6709 \
        --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --region "$REGION"
    
    log "⏳ Aguardando update da stack..."
    aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$REGION"
    
else
    log "Criando nova stack..."
    
    # Create stack
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=ClusterName,ParameterValue=cluster-bia-alb \
            ParameterKey=InstanceType,ParameterValue=t3.micro \
            ParameterKey=MinSize,ParameterValue=2 \
            ParameterKey=MaxSize,ParameterValue=2 \
            ParameterKey=DesiredCapacity,ParameterValue=2 \
            ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
            ParameterKey=SubnetIds,ParameterValue="subnet-068e3484d05611445,subnet-0c665b052ff5c528d" \
            ParameterKey=SecurityGroupId,ParameterValue=sg-00c1a082f04bc6709 \
        --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --region "$REGION"
    
    log "⏳ Aguardando criação da stack..."
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"
fi

# Verificar status final
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query 'Stacks[0].StackStatus' --output text)

if [[ "$STACK_STATUS" == "CREATE_COMPLETE" || "$STACK_STATUS" == "UPDATE_COMPLETE" ]]; then
    log "✅ Stack criada/atualizada com sucesso!"
    
    # Obter outputs
    log "📊 Informações do Cluster:"
    
    CLUSTER_NAME=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue' --output text)
    CLUSTER_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query 'Stacks[0].Outputs[?OutputKey==`ClusterArn`].OutputValue' --output text)
    ASG_NAME=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' --output text)
    
    info "Cluster Name: $CLUSTER_NAME"
    info "Cluster ARN: $CLUSTER_ARN"
    info "Auto Scaling Group: $ASG_NAME"
    
    # Verificar cluster ECS
    log "🔍 Verificando status do cluster ECS..."
    CLUSTER_STATUS=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" --query 'clusters[0].status' --output text)
    REGISTERED_INSTANCES=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" --query 'clusters[0].registeredContainerInstancesCount' --output text)
    
    info "Status do Cluster: $CLUSTER_STATUS"
    info "Instâncias Registradas: $REGISTERED_INSTANCES"
    
    if [[ "$CLUSTER_STATUS" == "ACTIVE" && "$REGISTERED_INSTANCES" -eq 2 ]]; then
        log "🎉 Cluster ECS está ATIVO com 2 instâncias registradas!"
        
        # Verificar instâncias EC2
        log "🔍 Verificando instâncias EC2..."
        RUNNING_INSTANCES=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=ECS Instance - $CLUSTER_NAME" "Name=instance-state-name,Values=running" \
            --region "$REGION" \
            --query 'Reservations[*].Instances[*].InstanceId' --output text | wc -w)
        
        info "Instâncias EC2 rodando: $RUNNING_INSTANCES"
        
        if [[ "$RUNNING_INSTANCES" -eq 2 ]]; then
            log "🎯 SUCESSO TOTAL! Cluster 100% funcional!"
            log "✅ Parâmetros do DESAFIO-3 atendidos:"
            log "   - Cluster name: cluster-bia-alb"
            log "   - Infrastructure: Amazon EC2 instances"
            log "   - Instance type: t3.micro"
            log "   - EC2 instance role: role-acesso-ssm"
            log "   - Desired capacity: 2 instâncias"
            log "   - Subnets: us-east-1a, us-east-1b"
            log "   - Security group: bia-ec2"
        else
            warn "Instâncias EC2 ainda inicializando..."
        fi
    else
        warn "Cluster ainda inicializando. Aguarde alguns minutos."
    fi
    
else
    error "Stack falhou com status: $STACK_STATUS"
    
    # Mostrar eventos de erro
    log "📋 Últimos eventos da stack:"
    aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --region "$REGION" \
        --query 'StackEvents[0:5].{Time:Timestamp,Status:ResourceStatus,Reason:ResourceStatusReason}' \
        --output table
    
    exit 1
fi

log "🏁 Deploy concluído!"
log "💡 Para deletar: aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION"