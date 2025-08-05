#!/bin/bash

# Script para adicionar ao ~/.bashrc para inicialização automática
# Adiciona FastMCP ao PATH e cria alias qbia

# Adicionar ao PATH
export PATH="/home/ec2-user/bia:$PATH"

# Criar alias para qbia
alias qbia='/home/ec2-user/bia/qbia'

# Função para iniciar FastMCP automaticamente quando necessário
start_fastmcp_if_needed() {
    if ! pgrep -f "fastmcp.*bia_fastmcp_server" > /dev/null; then
        echo "🔄 Iniciando FastMCP automaticamente..."
        /home/ec2-user/bia/scripts/start-fastmcp.sh > /dev/null 2>&1 &
    fi
}

# Iniciar FastMCP automaticamente quando fazer login
start_fastmcp_if_needed
