#!/bin/bash

# Script para sincronizar com S3
# Uso: ./s3.sh

BUCKET_NAME="desafios-fundamentais-bia-1763144658"

echo "📦 Sincronizando com S3..."
echo "🪣 Bucket: $BUCKET_NAME"

aws s3 sync client/build/ s3://$BUCKET_NAME/ --delete

echo "✅ Sincronização concluída!"
echo "🌐 Site disponível em: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
