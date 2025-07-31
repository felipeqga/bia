#!/bin/bash

# Deploy com Versionamento e Rollback - Projeto BIA
# Criado seguindo a filosofia de simplicidade do projeto

set -e

ECR_REGISTRY="387678648422.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY="bia"
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
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

# Função para gerar tag com timestamp
generate_tag() {
    echo "v$(date +'%Y%m%d-%H%M%S')"
}

# Função para listar últimas 10 imagens
list_images() {
    log "📋 Últimas 10 imagens no ECR:"
    aws ecr describe-images \
        --repository-name $ECR_REPOSITORY \
        --region $REGION \
        --query 'sort_by(imageDetails,&imagePushedAt)[-10:].[imageTags[0],imageDigest,imagePushedAt]' \
        --output table 2>/dev/null || {
        warn "Não foi possível listar imagens do ECR"
    }
}

# Função para obter imagem atual do service
get_current_image() {
    aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].taskDefinition' \
        --output text | xargs -I {} aws ecs describe-task-definition \
        --task-definition {} \
        --region $REGION \
        --query 'taskDefinition.containerDefinitions[0].image' \
        --output text
}

# Função para build e push
build_and_push() {
    local tag=$1
    
    log "🔐 Fazendo login no ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    log "🏗️ Fazendo build da imagem com tag: $tag"
    docker build -t $ECR_REPOSITORY:$tag .
    
    log "🏷️ Taggeando imagem..."
    docker tag $ECR_REPOSITORY:$tag $ECR_REGISTRY/$ECR_REPOSITORY:$tag
    docker tag $ECR_REPOSITORY:$tag $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    log "📤 Fazendo push para ECR..."
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$tag
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    log "✅ Imagem $tag enviada com sucesso!"
}

# Função para deploy
deploy() {
    local tag=$1
    
    log "🚀 Iniciando deploy da versão: $tag"
    
    # Salvar imagem atual antes do deploy
    local current_image=$(get_current_image)
    echo "$current_image" > .last-deployed-image
    log "💾 Imagem atual salva: $current_image"
    
    # Forçar novo deployment
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $REGION > /dev/null
    
    log "⏳ Aguardando deployment estabilizar..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    log "✅ Deploy da versão $tag concluído com sucesso!"
}

# Função para rollback
rollback() {
    if [ ! -f .last-deployed-image ]; then
        error "❌ Arquivo de backup não encontrado. Não é possível fazer rollback automático."
        info "💡 Use: $0 rollback <tag-especifica> para rollback manual"
        exit 1
    fi
    
    local previous_image=$(cat .last-deployed-image)
    log "🔄 Fazendo rollback para: $previous_image"
    
    # Extrair tag da imagem anterior
    local previous_tag=$(echo $previous_image | cut -d':' -f2)
    
    # Criar nova task definition com imagem anterior
    local current_task_def=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].taskDefinition' \
        --output text)
    
    # Registrar nova task definition com imagem anterior
    aws ecs describe-task-definition \
        --task-definition $current_task_def \
        --region $REGION \
        --query 'taskDefinition' > temp_task_def.json
    
    # Remover campos não necessários e atualizar imagem
    jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy) | .containerDefinitions[0].image = "'$previous_image'"' temp_task_def.json > rollback_task_def.json
    
    local new_task_def=$(aws ecs register-task-definition \
        --cli-input-json file://rollback_task_def.json \
        --region $REGION \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    # Atualizar service com nova task definition
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition $new_task_def \
        --region $REGION > /dev/null
    
    log "⏳ Aguardando rollback estabilizar..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    # Limpeza
    rm -f temp_task_def.json rollback_task_def.json
    
    log "✅ Rollback concluído com sucesso!"
    info "🔄 Aplicação voltou para: $previous_image"
}

# Função para rollback manual
rollback_to_tag() {
    local target_tag=$1
    local target_image="$ECR_REGISTRY/$ECR_REPOSITORY:$target_tag"
    
    log "🔄 Fazendo rollback manual para tag: $target_tag"
    
    # Verificar se a imagem existe
    aws ecr describe-images \
        --repository-name $ECR_REPOSITORY \
        --image-ids imageTag=$target_tag \
        --region $REGION > /dev/null 2>&1 || {
        error "❌ Tag $target_tag não encontrada no ECR"
        exit 1
    }
    
    # Salvar imagem atual
    local current_image=$(get_current_image)
    echo "$current_image" > .last-deployed-image
    
    # Mesmo processo do rollback automático
    local current_task_def=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].taskDefinition' \
        --output text)
    
    aws ecs describe-task-definition \
        --task-definition $current_task_def \
        --region $REGION \
        --query 'taskDefinition' > temp_task_def.json
    
    jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy) | .containerDefinitions[0].image = "'$target_image'"' temp_task_def.json > rollback_task_def.json
    
    local new_task_def=$(aws ecs register-task-definition \
        --cli-input-json file://rollback_task_def.json \
        --region $REGION \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition $new_task_def \
        --region $REGION > /dev/null
    
    log "⏳ Aguardando rollback estabilizar..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    rm -f temp_task_def.json rollback_task_def.json
    
    log "✅ Rollback para $target_tag concluído com sucesso!"
}

# Função para mostrar status
show_status() {
    log "📊 Status atual da aplicação:"
    
    local current_image=$(get_current_image)
    info "🖼️ Imagem atual: $current_image"
    
    local service_status=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].status' \
        --output text)
    info "🔄 Status do service: $service_status"
    
    local running_count=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].runningCount' \
        --output text)
    info "▶️ Tasks rodando: $running_count"
    
    # Obter IP público da aplicação
    local instance_id=$(aws ecs describe-container-instances \
        --cluster $CLUSTER_NAME \
        --container-instances $(aws ecs list-container-instances \
            --cluster $CLUSTER_NAME \
            --query 'containerInstanceArns[0]' \
            --output text) \
        --query 'containerInstances[0].ec2InstanceId' \
        --output text \
        --region $REGION 2>/dev/null)
    
    if [ "$instance_id" != "None" ] && [ "$instance_id" != "" ]; then
        local public_ip=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text \
            --region $REGION 2>/dev/null)
        
        if [ "$public_ip" != "None" ] && [ "$public_ip" != "" ]; then
            info "🌐 URL da aplicação: http://$public_ip"
            info "🔍 Health check: http://$public_ip/api/versao"
        fi
    fi
}

# Função de ajuda
show_help() {
    echo "🚀 Deploy com Versionamento - Projeto BIA"
    echo ""
    echo "Uso:"
    echo "  $0 deploy                    # Novo deploy com tag automática"
    echo "  $0 rollback                  # Rollback para versão anterior"
    echo "  $0 rollback <tag>            # Rollback para tag específica"
    echo "  $0 list                      # Listar últimas imagens"
    echo "  $0 status                    # Mostrar status atual"
    echo "  $0 help                      # Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 deploy                    # Deploy com tag v20250731-143022"
    echo "  $0 rollback                  # Volta para versão anterior"
    echo "  $0 rollback v20250731-120000 # Volta para tag específica"
    echo ""
}

# Main
case "${1:-help}" in
    "deploy")
        TAG=$(generate_tag)
        log "🚀 Iniciando deploy versionado - Tag: $TAG"
        build_and_push $TAG
        deploy $TAG
        show_status
        log "🎉 Deploy concluído! Versão: $TAG"
        ;;
    "rollback")
        if [ -n "$2" ]; then
            rollback_to_tag $2
        else
            rollback
        fi
        show_status
        ;;
    "list")
        list_images
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_help
        ;;
esac
