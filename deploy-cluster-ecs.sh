#!/bin/bash

# Script para Deploy do Cluster ECS - Projeto BIA
# Baseado no template oficial capturado do Console AWS

set -e

STACK_NAME="bia-ecs-cluster-stack"
TEMPLATE_FILE="/home/ec2-user/bia/ecs-cluster-console-template.yaml"
REGION="us-east-1"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Função para verificar se stack existe
check_stack_exists() {
    aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION >/dev/null 2>&1
}

# Função para aguardar conclusão do stack
wait_for_stack() {
    local operation=$1
    log "⏳ Aguardando conclusão da operação: $operation"
    
    aws cloudformation wait stack-${operation}-complete --stack-name $STACK_NAME --region $REGION
    
    if [ $? -eq 0 ]; then
        log "✅ Operação $operation concluída com sucesso!"
    else
        error "❌ Operação $operation falhou!"
        exit 1
    fi
}

# Função para mostrar outputs do stack
show_outputs() {
    log "📊 Outputs do Stack:"
    aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[*].{Key:OutputKey,Value:OutputValue}' --output table
}

# Função para verificar recursos criados
verify_resources() {
    log "🔍 Verificando recursos criados..."
    
    # Verificar cluster ECS
    CLUSTER_STATUS=$(aws ecs describe-clusters --clusters cluster-bia-alb --region $REGION --query 'clusters[0].status' --output text 2>/dev/null || echo "NOT_FOUND")
    info "ECS Cluster Status: $CLUSTER_STATUS"
    
    # Verificar instâncias registradas
    INSTANCE_COUNT=$(aws ecs describe-clusters --clusters cluster-bia-alb --region $REGION --query 'clusters[0].registeredContainerInstancesCount' --output text 2>/dev/null || echo "0")
    info "Container Instances Registradas: $INSTANCE_COUNT"
    
    # Verificar Auto Scaling Group
    ASG_STATUS=$(aws autoscaling describe-auto-scaling-groups --region $REGION --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `cluster-bia-alb`)].{Name:AutoScalingGroupName,Desired:DesiredCapacity,Running:length(Instances)}' --output table 2>/dev/null || echo "Nenhum ASG encontrado")
    info "Auto Scaling Group:"
    echo "$ASG_STATUS"
}

# Função principal para criar stack
create_stack() {
    log "🚀 Criando stack ECS Cluster: $STACK_NAME"
    
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --region $REGION \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters \
            ParameterKey=ECSClusterName,ParameterValue=cluster-bia-alb \
            ParameterKey=SecurityGroupIds,ParameterValue=sg-00c1a082f04bc6709 \
            ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
            ParameterKey=SubnetIds,ParameterValue=subnet-068e3484d05611445\,subnet-0c665b052ff5c528d \
            ParameterKey=InstanceType,ParameterValue=t3.micro \
            ParameterKey=MinSize,ParameterValue=2 \
            ParameterKey=MaxSize,ParameterValue=2 \
            ParameterKey=DesiredCapacity,ParameterValue=2 \
        --tags \
            Key=Project,Value=BIA \
            Key=Environment,Value=Production \
            Key=CreatedBy,Value=CloudFormation
    
    wait_for_stack "create"
    show_outputs
    verify_resources
}

# Função principal para atualizar stack
update_stack() {
    log "🔄 Atualizando stack ECS Cluster: $STACK_NAME"
    
    aws cloudformation update-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --region $REGION \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters \
            ParameterKey=ECSClusterName,ParameterValue=cluster-bia-alb \
            ParameterKey=SecurityGroupIds,ParameterValue=sg-00c1a082f04bc6709 \
            ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
            ParameterKey=SubnetIds,ParameterValue=subnet-068e3484d05611445\,subnet-0c665b052ff5c528d \
            ParameterKey=InstanceType,ParameterValue=t3.micro \
            ParameterKey=MinSize,ParameterValue=2 \
            ParameterKey=MaxSize,ParameterValue=2 \
            ParameterKey=DesiredCapacity,ParameterValue=2 \
        --tags \
            Key=Project,Value=BIA \
            Key=Environment,Value=Production \
            Key=UpdatedBy,Value=CloudFormation
    
    wait_for_stack "update"
    show_outputs
    verify_resources
}

# Função para deletar stack
delete_stack() {
    log "🗑️ Deletando stack ECS Cluster: $STACK_NAME"
    
    aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
    wait_for_stack "delete"
    
    log "✅ Stack deletado com sucesso!"
}

# Função principal
main() {
    local action=${1:-create}
    
    case $action in
        create)
            if check_stack_exists; then
                warn "Stack $STACK_NAME já existe. Use 'update' para atualizar ou 'delete' para deletar."
                exit 1
            fi
            create_stack
            ;;
        update)
            if ! check_stack_exists; then
                error "Stack $STACK_NAME não existe. Use 'create' para criar."
                exit 1
            fi
            update_stack
            ;;
        delete)
            if ! check_stack_exists; then
                warn "Stack $STACK_NAME não existe."
                exit 0
            fi
            delete_stack
            ;;
        verify)
            verify_resources
            ;;
        outputs)
            show_outputs
            ;;
        *)
            echo "Uso: $0 {create|update|delete|verify|outputs}"
            echo ""
            echo "Comandos:"
            echo "  create  - Criar novo stack ECS Cluster"
            echo "  update  - Atualizar stack existente"
            echo "  delete  - Deletar stack existente"
            echo "  verify  - Verificar recursos criados"
            echo "  outputs - Mostrar outputs do stack"
            exit 1
            ;;
    esac
}

# Verificar se é execução direta
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
