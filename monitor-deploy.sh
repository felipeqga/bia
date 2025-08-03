#!/bin/bash
echo "=== INICIANDO MONITORAMENTO DE DISPONIBILIDADE ==="
echo "URL: http://bia-1260066125.us-east-1.elb.amazonaws.com/api/versao"
echo "Duração: 5 minutos"
echo "Intervalo: 3 segundos"
echo "=========================================="

start_time=$(date +%s)
end_time=$((start_time + 300)) # 5 minutos

while [ $(date +%s) -lt $end_time ]; do
    response=$(curl -o /dev/null -s -w "%{http_code}" http://bia-1260066125.us-east-1.elb.amazonaws.com/api/versao)
    timestamp=$(date '+%H:%M:%S')
    
    if [ "$response" = "200" ]; then
        echo "✅ Status: $response - Hora: $timestamp"
    else
        echo "🚨 Status: $response - Hora: $timestamp - PROBLEMA DETECTADO!"
    fi
    
    sleep 3
done

echo "=========================================="
echo "=== MONITORAMENTO FINALIZADO ==="
