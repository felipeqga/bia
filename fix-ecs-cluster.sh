#!/bin/bash

echo "🎯 SCRIPT BIA - CORREÇÃO DO CLUSTER ECS"
echo "Inspirado no método organizado do usuário"
echo "=========================================="

# Definir variáveis do projeto BIA
export CLUSTER_NAME="cluster-bia-alb"
export REGION="us-east-1"
export CAPACITY_PROVIDER="bia-ecs-cluster-stack-v2-AsgCapacityProvider"

echo "📋 Configurações:"
echo "Cluster: ${CLUSTER_NAME}"
echo "Region: ${REGION}"
echo "Capacity Provider: ${CAPACITY_PROVIDER}"
echo ""

# Verificar instâncias do Auto Scaling Group
echo "🔍 1. Verificando instâncias do Auto Scaling Group..."
export INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "cluster-bia-alb-AutoScalingGroup" \
  --region ${REGION} \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text)

echo "Instâncias encontradas: ${INSTANCE_IDS}"
echo ""

# Verificar se cluster tem Capacity Providers
echo "🔍 2. Verificando Capacity Providers do cluster..."
export CLUSTER_PROVIDERS=$(aws ecs describe-clusters \
  --clusters ${CLUSTER_NAME} \
  --region ${REGION} \
  --query 'clusters[0].capacityProviders' \
  --output text)

echo "Capacity Providers no cluster: ${CLUSTER_PROVIDERS}"
echo ""

# Verificar instâncias registradas no cluster
echo "🔍 3. Verificando instâncias registradas no cluster..."
export REGISTERED_INSTANCES=$(aws ecs list-container-instances \
  --cluster ${CLUSTER_NAME} \
  --region ${REGION} \
  --query 'containerInstanceArns' \
  --output text)

echo "Instâncias registradas: ${REGISTERED_INSTANCES}"
echo ""

# Se não há instâncias registradas, forçar registro
if [ -z "$REGISTERED_INSTANCES" ] || [ "$REGISTERED_INSTANCES" = "None" ]; then
    echo "❌ PROBLEMA: Nenhuma instância registrada no cluster!"
    echo ""
    
    echo "🔧 4. Corrigindo configuração do ECS Agent nas instâncias..."
    
    for INSTANCE_ID in $INSTANCE_IDS; do
        echo "Corrigindo instância: $INSTANCE_ID"
        
        # Comando para corrigir ECS Agent
        aws ssm send-command \
          --instance-ids "$INSTANCE_ID" \
          --document-name "AWS-RunShellScript" \
          --parameters 'commands=[
            "echo \"Corrigindo ECS Agent na instância: '$INSTANCE_ID'\"",
            "sudo systemctl stop ecs",
            "sudo rm -rf /var/lib/ecs/data/ecs_agent_data.json",
            "echo \"ECS_CLUSTER='$CLUSTER_NAME'\" | sudo tee /etc/ecs/ecs.config",
            "echo \"ECS_BACKEND_HOST=\" | sudo tee -a /etc/ecs/ecs.config",
            "sudo systemctl start ecs",
            "sleep 15",
            "sudo systemctl status ecs",
            "echo \"Instância '$INSTANCE_ID' configurada para cluster '$CLUSTER_NAME'\""
          ]' \
          --region ${REGION} \
          --output text
        
        echo "Comando enviado para $INSTANCE_ID"
    done
    
    echo ""
    echo "⏳ Aguardando 60 segundos para ECS Agent se registrar..."
    sleep 60
    
    # Verificar novamente
    echo "🔍 5. Verificando registro após correção..."
    export REGISTERED_AFTER=$(aws ecs list-container-instances \
      --cluster ${CLUSTER_NAME} \
      --region ${REGION} \
      --query 'containerInstanceArns' \
      --output text)
    
    echo "Instâncias registradas após correção: ${REGISTERED_AFTER}"
    
    if [ -n "$REGISTERED_AFTER" ] && [ "$REGISTERED_AFTER" != "None" ]; then
        echo "✅ SUCESSO: Instâncias registradas no cluster!"
        
        # Contar instâncias registradas
        export REGISTERED_COUNT=$(aws ecs describe-clusters \
          --clusters ${CLUSTER_NAME} \
          --region ${REGION} \
          --query 'clusters[0].registeredContainerInstancesCount' \
          --output text)
        
        echo "Total de instâncias registradas: ${REGISTERED_COUNT}"
        
        # Forçar cfn-signal para completar CloudFormation
        echo ""
        echo "🔧 6. Enviando cfn-signal para completar CloudFormation..."
        
        for INSTANCE_ID in $INSTANCE_IDS; do
            aws ssm send-command \
              --instance-ids "$INSTANCE_ID" \
              --document-name "AWS-RunShellScript" \
              --parameters 'commands=[
                "/opt/aws/bin/cfn-signal -e 0 --stack bia-ecs-cluster-stack-v2 --resource ECSAutoScalingGroup --region us-east-1",
                "echo \"cfn-signal enviado da instância '$INSTANCE_ID'\""
              ]' \
              --region ${REGION} \
              --output text
        done
        
        echo "cfn-signal enviado de todas as instâncias"
        
    else
        echo "❌ FALHA: Instâncias ainda não registradas"
    fi
    
else
    echo "✅ SUCESSO: Instâncias já registradas no cluster!"
    echo "Total registradas: $(echo $REGISTERED_INSTANCES | wc -w)"
fi

echo ""
echo "🎯 SCRIPT CONCLUÍDO"
echo "==================="
echo "Próximos passos:"
echo "1. Verificar se CloudFormation completou"
echo "2. Criar ECS Service"
echo "3. Testar aplicação"
