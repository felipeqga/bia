#!/bin/bash

# Script de deploy completo para S3
# Uso: ./deploys3.sh [hom|prd]

AMBIENTE=${1:-hom}
BUCKET_NAME="desafios-fundamentais-bia-1763144658"

echo "🎯 DEPLOY S3 - DESAFIO SITE ESTÁTICO"
echo "🌍 Ambiente: $AMBIENTE"
echo "🪣 Bucket: $BUCKET_NAME"
echo "----------------------------------------"

# 1. Build React
echo "1️⃣ Executando build React..."
./reacts3.sh $AMBIENTE

if [ $? -ne 0 ]; then
    echo "❌ Erro no build React!"
    exit 1
fi

# 2. Sincronizar S3
echo "2️⃣ Sincronizando com S3..."
./s3.sh

if [ $? -ne 0 ]; then
    echo "❌ Erro na sincronização S3!"
    exit 1
fi

# 3. Validar deploy
echo "3️⃣ Validando deploy..."
SITE_URL="http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $SITE_URL)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Deploy realizado com sucesso!"
    echo "🌐 Site disponível em: $SITE_URL"
else
    echo "⚠️ Site pode não estar acessível (HTTP $HTTP_STATUS)"
fi

echo "----------------------------------------"
echo "🎉 DEPLOY S3 CONCLUÍDO!"
