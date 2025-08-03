#!/bin/bash

# Deploy com Versionamento e Rollback - Projeto BIA com ALB
# Criado seguindo a filosofia de simplicidade do projeto

set -e

ECR_REGISTRY="387678648422.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY="bia"
CLUSTER_NAME="cluster-bia-alb"
SERVICE_NAME="service-bia-alb"
REGION="us-east-1"
ALB_DNS="bia-1260066125.us-east-1.elb.amazonaws.com"

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
        error "Erro ao listar imagens do ECR"
        exit 1
    }
}

# Função para verificar se tag existe no ECR
check_tag_exists() {
    local tag=$1
    aws ecr describe-images \
        --repository-name $ECR_REPOSITORY \
        --image-ids imageTag=$tag \
        --region $REGION \
        --query 'imageDetails[0].imageTags[0]' \
        --output text 2>/dev/null | grep -q "$tag"
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

# Função para salvar imagem atual como backup
save_current_image() {
    local current_image=$(get_current_image)
    echo "$current_image" > .last-deployed-image
    info "💾 Imagem atual salva: $current_image"
}

# Função para fazer deploy
deploy() {
    local tag=$(generate_tag)
    
    log "🚀 Iniciando deploy versionado - Tag: $tag"
    
    # Salvar versão atual como backup
    save_current_image
    
    # Login no ECR
    log "🔐 Fazendo login no ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Build da imagem
    log "🏗️ Fazendo build da imagem com tag: $tag"
    docker build -t bia:$tag .
    
    # Tag para ECR
    log "🏷️ Taggeando imagem..."
    docker tag bia:$tag $ECR_REGISTRY/$ECR_REPOSITORY:$tag
    docker tag bia:$tag $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    # Push para ECR
    log "📤 Fazendo push para ECR..."
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$tag
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    log "✅ Imagem $tag enviada com sucesso!"
    
    # Deploy no ECS
    log "🚀 Iniciando deploy da versão: $tag"
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $REGION > /dev/null
    
    # Aguardar deployment estabilizar
    log "⏳ Aguardando deployment estabilizar..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    log "✅ Deploy da versão $tag concluído com sucesso!"
    
    # Mostrar status
    show_status
    
    log "🎉 Deploy concluído! Versão: $tag"
}

# Função para rollback
rollback() {
    local target_tag=$1
    
    if [ -z "$target_tag" ]; then
        # Rollback automático - usar backup
        if [ ! -f .last-deployed-image ]; then
            error "Arquivo de backup não encontrado. Use rollback manual especificando a tag."
            exit 1
        fi
        
        local backup_image=$(cat .last-deployed-image)
        log "🔄 Iniciando rollback automático para: $backup_image"
        
        # Extrair tag do backup
        target_tag=$(echo $backup_image | sed 's/.*://')
        if [ "$target_tag" = "latest" ]; then
            error "Backup aponta para 'latest'. Use rollback manual especificando a tag."
            exit 1
        fi
    else
        # Rollback manual - verificar se tag existe
        log "🔄 Iniciando rollback manual para tag: $target_tag"
        
        if ! check_tag_exists $target_tag; then
            error "Tag $target_tag não encontrada no ECR"
            list_images
            exit 1
        fi
        
        # Salvar versão atual como backup antes do rollback
        save_current_image
    fi
    
    # Criar nova task definition com a imagem de rollback
    local current_task_def=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].taskDefinition' \
        --output text)
    
    # Obter definição atual e modificar imagem
    aws ecs describe-task-definition \
        --task-definition $current_task_def \
        --region $REGION \
        --query 'taskDefinition' > temp_task_def.json
    
    # Remover campos read-only
    jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)' temp_task_def.json > rollback_task_def.json
    
    # Atualizar imagem
    jq --arg image "$ECR_REGISTRY/$ECR_REPOSITORY:$target_tag" '.containerDefinitions[0].image = $image' rollback_task_def.json > rollback_task_def_updated.json
    
    # Registrar nova task definition
    aws ecs register-task-definition \
        --cli-input-json file://rollback_task_def_updated.json \
        --region $REGION > /dev/null
    
    # Atualizar service
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $REGION > /dev/null
    
    # Aguardar estabilização
    log "⏳ Aguardando rollback estabilizar..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    # Limpeza
    rm -f temp_task_def.json rollback_task_def.json rollback_task_def_updated.json
    
    log "✅ Rollback para $target_tag concluído com sucesso!"
    
    # Mostrar status
    show_status
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
    
    local running_tasks=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].runningCount' \
        --output text)
    info "▶️ Tasks rodando: $running_tasks"
    
    info "🌐 URL da aplicação: http://$ALB_DNS"
    info "🔍 Health check: http://$ALB_DNS/api/versao"
}

# Função para mostrar ajuda
show_help() {
    echo "Deploy Versionado com ALB - Projeto BIA"
    echo ""
    echo "Uso: $0 [comando] [opções]"
    echo ""
    echo "Comandos:"
    echo "  deploy                    - Fazer deploy de nova versão"
    echo "  rollback                  - Rollback para versão anterior (automático)"
    echo "  rollback <tag>            - Rollback para tag específica (manual)"
    echo "  list                      - Listar últimas 10 versões no ECR"
    echo "  status                    - Mostrar status atual da aplicação"
    echo "  help                      - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 deploy                 # Deploy nova versão"
    echo "  $0 rollback               # Rollback automático"
    echo "  $0 rollback v20250801-120000  # Rollback para tag específica"
    echo "  $0 list                   # Ver versões disponíveis"
    echo "  $0 status                 # Ver status atual"
    echo ""
    echo "Configuração atual:"
    echo "  Cluster: $CLUSTER_NAME"
    echo "  Service: $SERVICE_NAME"
    echo "  ALB DNS: $ALB_DNS"
    echo "  ECR: $ECR_REGISTRY/$ECR_REPOSITORY"
}

# Main
case "$1" in
    deploy)
        deploy
        ;;
    rollback)
        rollback "$2"
        ;;
    list)
        list_images
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Comando inválido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac