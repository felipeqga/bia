#!/bin/bash

# Script executado pelo alias qbia para carregar contexto completo

echo "🤖 Amazon Q BIA - Carregando contexto completo..."
echo "📚 Preparando para ler todos os arquivos .md do projeto..."

# Navegar para diretório do projeto
cd /home/ec2-user/bia

# Ativar MCP server completo (filesystem + ECS + database)
cp .amazonq/mcp-bia-completo.json mcp.json 2>/dev/null

echo "✅ MCP servers ativados (filesystem + ECS + database)"
echo "📋 Contexto automático configurado"
echo ""
echo "🚀 Iniciando Amazon Q com contexto completo..."
echo "   Amazon Q lerá automaticamente todos os arquivos .md"
echo "   e ficará completamente contextualizado."
echo ""

# Executar Amazon Q CLI
q
