#!/bin/bash

echo "🔧 Configurando alias DEFINITIVO para Amazon Q com contexto completo BIA..."

# Remover aliases antigos
sed -i '/# Amazon Q com contexto BIA/,/^$/d' ~/.bashrc

# Adicionar alias definitivo
cat >> ~/.bashrc << 'EOF'

# Amazon Q BIA - Contexto Completo Definitivo
alias qbia='cd /home/ec2-user/bia && cp .amazonq/mcp-bia-completo.json mcp.json 2>/dev/null; echo "🤖 Amazon Q BIA - Contexto Completo Carregado"; echo "📋 Filesystem + ECS + Database + Todas as Regras"; echo "📚 Acesso a: regras, histórico, guias, documentação"; echo "💡 Dica: Pergunte sobre qualquer aspecto do projeto BIA!"; q'
alias qecs='cd /home/ec2-user/bia && cp .amazonq/mcp-ecs.json mcp.json 2>/dev/null; echo "🚀 Amazon Q - ECS Especializado"; q'
alias qdb='cd /home/ec2-user/bia && cp .amazonq/mcp-db.json mcp.json 2>/dev/null; echo "🗄️ Amazon Q - Database Direto"; q'
alias qclean='cd /home/ec2-user/bia && rm -f mcp.json; echo "🧹 Amazon Q - Modo Limpo"; q'

EOF

echo "✅ Alias DEFINITIVO configurado!"
echo ""
echo "📋 Comandos disponíveis:"
echo "  qbia   - Amazon Q BIA COMPLETO (Filesystem + ECS + DB + Regras + Contexto)"
echo "  qecs   - Amazon Q só ECS especializado"
echo "  qdb    - Amazon Q só Database"
echo "  qclean - Amazon Q limpo"
echo ""
echo "🎯 RECOMENDADO: Use 'qbia' - tem acesso a TUDO!"
echo ""
echo "🔄 Execute: source ~/.bashrc"
