#!/bin/bash
# Parar o ECS Agent para evitar race condition
stop ecs

# Configurar o cluster ECS
echo ECS_CLUSTER=cluster-bia-alb > /etc/ecs/ecs.conf

# Atualizar o sistema
yum update -y

# Instalar Docker se não estiver instalado
yum install -y docker
service docker start
chkconfig docker on

# Iniciar o ECS Agent
start ecs

# Verificar se o agent está rodando
service ecs status