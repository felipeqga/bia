#!/bin/bash

echo "🔧 Corrigindo alias para Amazon Q com MCP completo..."

# Remover aliases antigos e adicionar corretos
sed -i '/# Amazon Q com contexto BIA/,/^$/d' ~/.bashrc

# Adicionar aliases corretos
cat >> ~/.bashrc << 'EOF'

# Amazon Q com contexto BIA - MCP Servers Especializados
alias qbia='cd /home/ec2-user/bia && cp .amazonq/mcp-completo-tudo.json mcp.json 2>/dev/null; echo "🤖 Amazon Q iniciando com TUDO: Filesystem + ECS + Database"; echo "📋 Tools: filesystem, ecs_resouce_management, postgres queries"; q'
alias qecs='cd /home/ec2-user/bia && cp .amazonq/mcp-ecs.json mcp.json 2>/dev/null; echo "🚀 Amazon Q com ECS especializado"; q'
alias qdb='cd /home/ec2-user/bia && cp .amazonq/mcp-db.json mcp.json 2>/dev/null; echo "🗄️ Amazon Q com Database direto"; q'
alias qclean='cd /home/ec2-user/bia && rm -f mcp.json; echo "🧹 Amazon Q limpo (sem MCP)"; q'

EOF

echo "✅ Aliases corrigidos!"
echo ""
echo "📋 Comandos disponíveis:"
echo "  qbia   - Amazon Q com TUDO (Filesystem + ECS + Database)"
echo "  qecs   - Amazon Q só com ECS especializado"
echo "  qdb    - Amazon Q só com Database direto"
echo "  qclean - Amazon Q limpo (sem MCP)"
echo "  q      - Amazon Q padrão"
echo ""
echo "🔄 Execute: source ~/.bashrc"
