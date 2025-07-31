#!/bin/bash

echo "🔧 Configurando alias para Amazon Q com contexto..."

# Adicionar alias ao .bashrc
cat >> ~/.bashrc << 'EOF'

# Amazon Q com contexto BIA
alias qbia='cd /home/ec2-user/bia && cp .amazonq/mcp-contexto-completo.json mcp.json 2>/dev/null; echo "🤖 Amazon Q iniciando com contexto BIA..."; echo "📋 Contexto: histórico, guias, scripts, documentação"; q'
alias qclean='cd /home/ec2-user/bia && rm -f mcp.json; echo "🧹 Contexto limpo"; q'

EOF

echo "✅ Aliases configurados!"
echo ""
echo "📋 Comandos disponíveis:"
echo "  qbia   - Amazon Q com contexto completo do projeto BIA"
echo "  qclean - Amazon Q sem contexto (limpo)"
echo "  q      - Amazon Q padrão"
echo ""
echo "🔄 Execute: source ~/.bashrc"
