#!/bin/bash

# Script para testar container BIA com RDS
# Aguarda RDS ficar disponível e testa conexão

echo "🔍 Verificando status do RDS..."

while true; do
    STATUS=$(aws rds describe-db-instances --db-instance-identifier bia --query 'DBInstances[0].DBInstanceStatus' --output text --region us-east-1)
    
    if [ "$STATUS" = "available" ]; then
        echo "✅ RDS disponível!"
        break
    else
        echo "⏳ RDS ainda em status: $STATUS - aguardando..."
        sleep 30
    fi
done

# Obter endpoint do RDS
ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier bia --query 'DBInstances[0].Endpoint.Address' --output text --region us-east-1)
echo "🌐 Endpoint RDS: $ENDPOINT"

# Testar container com RDS
echo "🚀 Testando container BIA com RDS..."
docker run -d \
  --name bia-test-rds \
  -p 3004:8080 \
  -e NODE_ENV=production \
  -e DB_HOST=$ENDPOINT \
  -e DB_USER=postgres \
  -e DB_PWD=Kgegwlaj6mAIxzHaEqgo \
  -e DB_PORT=5432 \
  387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest

echo "⏳ Aguardando container inicializar..."
sleep 10

# Testar API
echo "🧪 Testando API..."
curl -s http://localhost:3004/api/versao

echo ""
echo "✅ Teste concluído!"
echo "🌐 Container rodando em: http://localhost:3004"
echo "📊 Para parar: docker stop bia-test-rds && docker rm bia-test-rds"
