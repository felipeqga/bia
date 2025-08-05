#!/bin/bash

# Script de Inicialização Automática do FastMCP
# Executa automaticamente quando a instância inicia ou quando qbia é executado

FASTMCP_DIR="/home/ec2-user/bia/fastmcp-server"
FASTMCP_SERVER="bia_fastmcp_server.py"
FASTMCP_PORT="8080"
FASTMCP_PID_FILE="/tmp/bia-fastmcp.pid"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Verificar se FastMCP já está rodando
if [ -f "$FASTMCP_PID_FILE" ]; then
    PID=$(cat "$FASTMCP_PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        log "✅ FastMCP já está rodando (PID: $PID)"
        exit 0
    else
        log "🔄 Removendo PID file obsoleto"
        rm -f "$FASTMCP_PID_FILE"
    fi
fi

# Verificar se a porta está em uso
if netstat -tuln | grep -q ":$FASTMCP_PORT "; then
    log "⚠️  Porta $FASTMCP_PORT já está em uso"
    exit 1
fi

# Instalar FastMCP se não estiver instalado
if ! command -v fastmcp &> /dev/null; then
    log "📦 Instalando FastMCP..."
    pip3 install fastmcp
fi

# Iniciar FastMCP em background
log "🚀 Iniciando FastMCP em background..."
cd "$FASTMCP_DIR"

nohup fastmcp run "$FASTMCP_SERVER:mcp" --transport sse --port "$FASTMCP_PORT" --host 0.0.0.0 > /tmp/bia-fastmcp.log 2>&1 &
FASTMCP_PID=$!

# Salvar PID
echo "$FASTMCP_PID" > "$FASTMCP_PID_FILE"

# Aguardar inicialização
sleep 3

# Verificar se iniciou corretamente
if ps -p "$FASTMCP_PID" > /dev/null 2>&1; then
    log "✅ FastMCP iniciado com sucesso (PID: $FASTMCP_PID)"
    log "🌐 Servidor disponível em: http://localhost:$FASTMCP_PORT/sse/"
else
    log "❌ Falha ao iniciar FastMCP"
    rm -f "$FASTMCP_PID_FILE"
    exit 1
fi
