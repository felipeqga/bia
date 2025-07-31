#!/bin/bash

echo "🚀 Iniciando cluster ECS completo..."

# Passo 1: Reativar Auto Scaling Group
echo "📈 Reativando Auto Scaling Group..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "Infra-ECS-Cluster-cluster-bia-581e3f53-ECSAutoScalingGroup-bFQW9Kb1APvu" \
  --min-size 1 \
  --desired-capacity 1 \
  --region us-east-1

echo "⏳ Aguardando nova instância EC2 (2-3 minutos)..."
sleep 120

# Verificar se instância foi criada
echo "🔍 Verificando nova instância..."
NEW_INSTANCE=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "Infra-ECS-Cluster-cluster-bia-581e3f53-ECSAutoScalingGroup-bFQW9Kb1APvu" \
  --region us-east-1 \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

if [ "$NEW_INSTANCE" != "None" ]; then
    echo "✅ Nova instância criada: $NEW_INSTANCE"
    
    # Aguardar instância registrar no ECS
    echo "⏳ Aguardando registro no ECS..."
    sleep 60
    
    # Passo 2: Reativar ECS Service
    echo "🔄 Reativando ECS Service..."
    aws ecs update-service \
      --cluster cluster-bia \
      --service service-bia \
      --desired-count 1 \
      --region us-east-1
    
    echo "⏳ Aguardando service estabilizar..."
    aws ecs wait services-stable --cluster cluster-bia --services service-bia --region us-east-1
    
    # Obter novo IP público
    NEW_IP=$(aws ec2 describe-instances \
      --instance-ids $NEW_INSTANCE \
      --region us-east-1 \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
    
    echo "🎉 Cluster reativado com sucesso!"
    echo "🌐 Nova aplicação: http://$NEW_IP"
    echo "🔍 Health check: http://$NEW_IP/api/versao"
    
    # Testar aplicação
    echo "🧪 Testando aplicação..."
    sleep 30
    curl -s http://$NEW_IP/api/versao && echo " ✅ Aplicação funcionando!" || echo " ❌ Aplicação ainda não está respondendo"
    
else
    echo "❌ Erro: Nova instância não foi criada"
fi
