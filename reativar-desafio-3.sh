#!/bin/bash

echo "🚀 REATIVANDO DESAFIO-3 - MÉTODO RÁPIDO"
echo "======================================"

# Definir variáveis
export CLUSTER_NAME="cluster-bia-alb"
export REGION="us-east-1"
export STACK_NAME="bia-cluster-template-oficial"

echo "📋 Configurações:"
echo "Cluster: ${CLUSTER_NAME}"
echo "Region: ${REGION}"
echo "Stack: ${STACK_NAME}"
echo ""

echo "🔄 PASSO 1: Criando Cluster ECS..."
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file:///home/ec2-user/bia/templates/ecs-cluster-template-console-oficial.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ECSClusterName,ParameterValue=${CLUSTER_NAME} \
    ParameterKey=SecurityGroupIds,ParameterValue=sg-00c1a082f04bc6709 \
    ParameterKey=VpcId,ParameterValue=vpc-08b8e37ee6ff01860 \
    ParameterKey=SubnetIds,ParameterValue="subnet-068e3484d05611445,subnet-0c665b052ff5c528d" \
  --tags \
    Key=Project,Value=BIA \
    Key=CreatedBy,Value=Script-Reativacao \
    Key=Environment,Value=Production

if [ $? -eq 0 ]; then
    echo "✅ Stack criado com sucesso!"
else
    echo "❌ Erro ao criar stack"
    exit 1
fi

echo ""
echo "⏳ Aguardando cluster ficar pronto (3 minutos)..."
sleep 180

echo ""
echo "🔄 PASSO 2: Criando ALB..."
export ALB_ARN=$(aws elbv2 create-load-balancer \
  --name bia \
  --subnets subnet-068e3484d05611445 subnet-0c665b052ff5c528d \
  --security-groups sg-081297c2a6694761b \
  --scheme internet-facing \
  --type application \
  --tags Key=Project,Value=BIA \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "ALB ARN: ${ALB_ARN}"

# Aguardar ALB ficar ativo
echo "⏳ Aguardando ALB ficar ativo..."
sleep 60

export ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${ALB_ARN} \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS: ${ALB_DNS}"

echo ""
echo "🔄 PASSO 3: Criando Target Group..."
export TG_ARN=$(aws elbv2 create-target-group \
  --name tg-bia \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-08b8e37ee6ff01860 \
  --health-check-path /api/versao \
  --health-check-interval-seconds 10 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --target-type instance \
  --tags Key=Project,Value=BIA \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group ARN: ${TG_ARN}"

# Otimizar deregistration delay
aws elbv2 modify-target-group-attributes \
  --target-group-arn ${TG_ARN} \
  --attributes Key=deregistration_delay.timeout_seconds,Value=5

echo ""
echo "🔄 PASSO 4: Criando Listeners..."
# HTTP Listener (redirecionamento)
aws elbv2 create-listener \
  --load-balancer-arn ${ALB_ARN} \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'

# HTTPS Listener
aws elbv2 create-listener \
  --load-balancer-arn ${ALB_ARN} \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:aws:acm:us-east-1:387678648422:certificate/01b4733b-19eb-4ec8-b5e3-cb6e6eb929d7 \
  --default-actions Type=forward,TargetGroupArn=${TG_ARN}

echo ""
echo "🔄 PASSO 5: Registrando Task Definition..."
aws ecs register-task-definition \
  --family task-def-bia-alb \
  --network-mode bridge \
  --requires-compatibilities EC2 \
  --container-definitions '[{
    "name": "bia",
    "image": "387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest",
    "memory": 512,
    "essential": true,
    "portMappings": [{"containerPort": 8080, "protocol": "tcp"}],
    "environment": [
      {"name": "DB_HOST", "value": "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"},
      {"name": "DB_USER", "value": "postgres"},
      {"name": "DB_PWD", "value": "Kgegwlaj6mAIxzHaEqgo"},
      {"name": "DB_PORT", "value": "5432"},
      {"name": "NODE_ENV", "value": "production"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/task-def-bia-alb",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]' \
  --tags key=Project,value=BIA

echo ""
echo "🔄 PASSO 6: Criando ECS Service..."
aws ecs create-service \
  --cluster ${CLUSTER_NAME} \
  --service-name service-bia-alb \
  --task-definition task-def-bia-alb \
  --desired-count 2 \
  --launch-type EC2 \
  --load-balancers targetGroupArn=${TG_ARN},containerName=bia,containerPort=8080 \
  --deployment-configuration maximumPercent=200,minimumHealthyPercent=50 \
  --placement-strategy type=spread,field=attribute:ecs.availability-zone \
  --tags key=Project,value=BIA

echo ""
echo "🔄 PASSO 7: Atualizando Route 53..."
aws route53 change-resource-record-sets \
  --hosted-zone-id Z01975963I2P5MLACDOV9 \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "desafio3.eletroboards.com.br",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'${ALB_DNS}'"}]
      }
    }]
  }'

echo ""
echo "⏳ Aguardando deployment completar (2 minutos)..."
sleep 120

echo ""
echo "🎯 VERIFICAÇÃO FINAL:"
echo "==================="

# Verificar cluster
echo "📊 Cluster Status:"
aws ecs describe-clusters --clusters ${CLUSTER_NAME} --query 'clusters[0].{Status:status,Instances:registeredContainerInstancesCount}'

# Verificar service
echo ""
echo "📊 Service Status:"
aws ecs describe-services --cluster ${CLUSTER_NAME} --services service-bia-alb --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Verificar target health
echo ""
echo "📊 Target Health:"
aws elbv2 describe-target-health --target-group-arn ${TG_ARN} --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}'

echo ""
echo "🎉 DESAFIO-3 REATIVADO!"
echo "====================="
echo "URL: https://desafio3.eletroboards.com.br"
echo "Teste: curl https://desafio3.eletroboards.com.br/api/versao"
echo ""
echo "💰 Para economizar novamente, execute:"
echo "./pausar-desafio-3.sh"
