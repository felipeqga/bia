#!/bin/bash

# Script para build do React com VITE_API_URL
# Uso: ./reacts3.sh [hom|prd]

AMBIENTE=${1:-hom}

if [ "$AMBIENTE" = "prd" ]; then
    API_URL="https://desafio3.eletroboards.com.br"
else
    API_URL="http://bia-1751550233.us-east-1.elb.amazonaws.com"
fi

echo "🚀 Fazendo build React para ambiente: $AMBIENTE"
echo "📡 API URL: $API_URL"

cd client
VITE_API_URL=$API_URL npm run build
cd ..

echo "✅ Build concluído!"
