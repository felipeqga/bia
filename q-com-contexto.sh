#!/bin/bash

echo "🤖 Iniciando Amazon Q com contexto completo do projeto BIA..."
echo ""

# Ativar MCP server de contexto
cd /home/ec2-user/bia
cp .amazonq/mcp-contexto-completo.json mcp.json

echo "📋 Contexto carregado:"
echo "  ✅ Histórico de conversas"
echo "  ✅ Guias de infraestrutura"
echo "  ✅ Scripts de deploy"
echo "  ✅ Documentação completa"
echo "  ✅ Status de economia"
echo ""

echo "💡 Dica: Pergunte sobre qualquer aspecto do projeto BIA!"
echo "📚 Arquivos disponíveis: historico-conversas-amazonq.md, guias, scripts..."
echo ""

# Iniciar Amazon Q
q
