#!/bin/bash

echo "🛑 Parando cluster ECS completo para economia..."

# Passo 1: Parar ECS Service
echo "🔄 Parando ECS Service..."
aws ecs update-service \
  --cluster cluster-bia \
  --service service-bia \
  --desired-count 0 \
  --region us-east-1

echo "⏳ Aguardando service parar..."
sleep 30

# Passo 2: Parar Auto Scaling Group
echo "📉 Parando Auto Scaling Group..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "Infra-ECS-Cluster-cluster-bia-581e3f53-ECSAutoScalingGroup-bFQW9Kb1APvu" \
  --min-size 0 \
  --desired-capacity 0 \
  --region us-east-1

echo "⏳ Aguardando instância terminar..."
sleep 60

# Verificar status
ASG_STATUS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "Infra-ECS-Cluster-cluster-bia-581e3f53-ECSAutoScalingGroup-bFQW9Kb1APvu" \
  --region us-east-1 \
  --query 'AutoScalingGroups[0].DesiredCapacity' \
  --output text)

if [ "$ASG_STATUS" = "0" ]; then
    echo "✅ Cluster parado com sucesso!"
    echo "💰 Economia ativada - EC2 terminada"
    echo "📊 Custos: ~$0/mês (apenas storage mínimo)"
    echo ""
    echo "🚀 Para reativar: ./iniciar-cluster-completo.sh"
else
    echo "❌ Erro ao parar cluster"
fi
