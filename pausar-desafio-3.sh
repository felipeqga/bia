#!/bin/bash

echo "💰 PAUSANDO DESAFIO-3 PARA ECONOMIA"
echo "==================================="

# Definir variáveis
export CLUSTER_NAME="cluster-bia-alb"
export REGION="us-east-1"
export STACK_NAME="bia-cluster-template-oficial"

echo "📋 Configurações:"
echo "Cluster: ${CLUSTER_NAME}"
echo "Region: ${REGION}"
echo "Stack: ${STACK_NAME}"
echo ""

echo "🔄 PASSO 1: Reduzindo ECS Service para 0..."
aws ecs update-service \
  --cluster ${CLUSTER_NAME} \
  --service service-bia-alb \
  --desired-count 0

echo "⏳ Aguardando tasks pararem..."
sleep 30

echo ""
echo "🔄 PASSO 2: Deletando ECS Service..."
aws ecs delete-service \
  --cluster ${CLUSTER_NAME} \
  --service service-bia-alb

echo ""
echo "🔄 PASSO 3: Obtendo ARNs dos recursos..."
export ALB_ARN=$(aws elbv2 describe-load-balancers --names bia --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
export TG_ARN=$(aws elbv2 describe-target-groups --names tg-bia --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "" ]; then
    echo "🔄 PASSO 4: Deletando ALB..."
    aws elbv2 delete-load-balancer --load-balancer-arn ${ALB_ARN}
    echo "⏳ Aguardando ALB ser deletado..."
    sleep 60
else
    echo "ℹ️ ALB não encontrado (já deletado)"
fi

if [ "$TG_ARN" != "None" ] && [ "$TG_ARN" != "" ]; then
    echo "🔄 PASSO 5: Deletando Target Group..."
    aws elbv2 delete-target-group --target-group-arn ${TG_ARN}
else
    echo "ℹ️ Target Group não encontrado (já deletado)"
fi

echo ""
echo "🔄 PASSO 6: Deletando CloudFormation Stack..."
aws cloudformation delete-stack --stack-name ${STACK_NAME}

echo "⏳ Aguardando stack ser deletado (3 minutos)..."
sleep 180

echo ""
echo "🔍 VERIFICAÇÃO FINAL:"
echo "===================="

# Verificar se stack foi deletado
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "✅ Stack deletado com sucesso"
else
    echo "⏳ Stack ainda sendo deletado: ${STACK_STATUS}"
fi

# Verificar clusters
CLUSTER_COUNT=$(aws ecs list-clusters --query 'clusterArns' --output text | wc -w)
echo "📊 Clusters ECS restantes: ${CLUSTER_COUNT}"

# Verificar instâncias EC2
INSTANCE_COUNT=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=BIA" "Name=instance-state-name,Values=running,pending,stopping" --query 'Reservations[*].Instances[*].InstanceId' --output text | wc -w)
echo "📊 Instâncias EC2 BIA ativas: ${INSTANCE_COUNT}"

# Verificar ALBs
ALB_COUNT=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?LoadBalancerName==`bia`]' --output text | wc -l)
echo "📊 ALBs BIA restantes: ${ALB_COUNT}"

echo ""
if [ ${CLUSTER_COUNT} -eq 0 ] && [ ${INSTANCE_COUNT} -eq 0 ] && [ ${ALB_COUNT} -eq 0 ]; then
    echo "🎉 DESAFIO-3 PAUSADO COM SUCESSO!"
    echo "💰 Recursos caros deletados - economia ativa"
    echo ""
    echo "🚀 Para reativar rapidamente, execute:"
    echo "./reativar-desafio-3.sh"
else
    echo "⚠️ Alguns recursos ainda estão sendo deletados"
    echo "Aguarde alguns minutos e verifique novamente"
fi

echo ""
echo "📋 RECURSOS PRESERVADOS (sem custo):"
echo "- Security Groups (bia-alb, bia-ec2, bia-db)"
echo "- RDS Database (bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com)"
echo "- ECR Repository (387678648422.dkr.ecr.us-east-1.amazonaws.com/bia)"
echo "- Route 53 Records (desafio3.eletroboards.com.br)"
echo "- SSL Certificates (*.eletroboards.com.br)"
echo "- Task Definition (task-def-bia-alb)"
echo "- CloudWatch Log Groups"
echo ""
echo "💡 Estes recursos não geram custo quando não estão em uso!"
