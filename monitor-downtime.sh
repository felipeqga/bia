#!/bin/bash

# Script de Monitoramento de Downtime - Deploy DEPLOY-OTIMIZADO-V2
# Baseado nas otimizações aplicadas: Health Check 10s, Deregistration 5s, MaximumPercent 200%

ALB_DNS="bia-1751550233.us-east-1.elb.amazonaws.com"
API_ENDPOINT="http://${ALB_DNS}/api/versao"
LOG_FILE="/home/ec2-user/bia/downtime-monitor-$(date +%Y%m%d-%H%M%S).log"

echo "🚀 MONITORAMENTO DE DOWNTIME - DEPLOY OTIMIZADO V2" | tee -a $LOG_FILE
echo "⏰ Iniciado em: $(date)" | tee -a $LOG_FILE
echo "🎯 Endpoint: $API_ENDPOINT" | tee -a $LOG_FILE
echo "📊 Configurações otimizadas aplicadas:" | tee -a $LOG_FILE
echo "   - Health Check: 10s (3x mais rápido)" | tee -a $LOG_FILE
echo "   - Deregistration: 5s (6x mais rápido)" | tee -a $LOG_FILE
echo "   - MaximumPercent: 200% (deploy paralelo)" | tee -a $LOG_FILE
echo "   - Resultado esperado: ZERO DOWNTIME" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE

# Contadores
SUCCESS_COUNT=0
ERROR_COUNT=0
TOTAL_COUNT=0
START_TIME=$(date +%s)

# Função para verificar status
check_status() {
    local timestamp=$(date '+%H:%M:%S')
    local response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$API_ENDPOINT" 2>/dev/null)
    
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    if [ "$response" = "200" ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "✅ $timestamp - Status: $response - OK ($SUCCESS_COUNT/$TOTAL_COUNT)" | tee -a $LOG_FILE
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        echo "❌ $timestamp - Status: $response - ERRO ($ERROR_COUNT/$TOTAL_COUNT)" | tee -a $LOG_FILE
    fi
}

# Monitoramento contínuo
echo "🔍 Iniciando monitoramento (Ctrl+C para parar)..." | tee -a $LOG_FILE

while true; do
    check_status
    sleep 2
done