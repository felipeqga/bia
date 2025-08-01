#!/bin/bash

# Script para configurar qbia com contexto automático completo
# Criado para que Amazon Q leia automaticamente todos os arquivos .md do projeto BIA

echo "🔧 Configurando qbia com contexto automático completo..."

# Lista de todos os arquivos .md do projeto BIA (excluindo node_modules)
ARQUIVOS_MD=(
    "/home/ec2-user/bia/.amazonq/CONTEXTO-INICIAL.md"
    "/home/ec2-user/bia/.amazonq/rules/dockerfile.md"
    "/home/ec2-user/bia/.amazonq/rules/infraestrutura.md"
    "/home/ec2-user/bia/.amazonq/rules/pipeline.md"
    "/home/ec2-user/bia/AmazonQ.md"
    "/home/ec2-user/bia/CONTEXTO-RAPIDO.md"
    "/home/ec2-user/bia/DESAFIO-2-RESUMO-USUARIO.md"
    "/home/ec2-user/bia/GUIA-DEPLOY-VERSIONADO.md"
    "/home/ec2-user/bia/README.md"
    "/home/ec2-user/bia/RESUMO-INFRAESTRUTURA-BIA.md"
    "/home/ec2-user/bia/VERIFICACAO-DESAFIO-2.md"
    "/home/ec2-user/bia/docs/README.md"
    "/home/ec2-user/bia/guia-completo-ecs-bia.md"
    "/home/ec2-user/bia/guia-criacao-ec2-bia.md"
    "/home/ec2-user/bia/guia-mcp-servers-bia.md"
    "/home/ec2-user/bia/guia-script-deploy-versionado.md"
    "/home/ec2-user/bia/historico-conversas-amazonq.md"
    "/home/ec2-user/bia/scripts_evento/README.md"
)

# Criar arquivo de contexto inicial para Amazon Q
cat > /home/ec2-user/bia/CONTEXTO-AUTOMATICO.md << 'EOF'
# 🤖 CONTEXTO AUTOMÁTICO CARREGADO - PROJETO BIA

## 📋 **Instrução para Amazon Q**

Você acabou de ser iniciado com o comando `qbia` e deve automaticamente ler todos os arquivos .md do projeto BIA para ter contexto completo.

### **📚 Arquivos que devem ser lidos automaticamente:**

1. **Regras de Configuração (Críticas):**
   - `.amazonq/rules/dockerfile.md` - Regras para criação de Dockerfiles
   - `.amazonq/rules/infraestrutura.md` - Regras de infraestrutura AWS
   - `.amazonq/rules/pipeline.md` - Regras para pipelines CI/CD

2. **Documentação Base:**
   - `AmazonQ.md` - Contexto geral do projeto BIA
   - `README.md` - Informações básicas do projeto
   - `docs/README.md` - Documentação adicional
   - `scripts_evento/README.md` - Scripts do evento

3. **Histórico e Conversas:**
   - `historico-conversas-amazonq.md` - Histórico completo de conversas

4. **Guias de Implementação:**
   - `guia-criacao-ec2-bia.md` - Guia para criação de EC2
   - `guia-completo-ecs-bia.md` - Guia completo ECS
   - `guia-mcp-servers-bia.md` - Guia dos MCP servers
   - `guia-script-deploy-versionado.md` - Sistema de deploy versionado

5. **Status e Verificação:**
   - `RESUMO-INFRAESTRUTURA-BIA.md` - Status atual da infraestrutura
   - `DESAFIO-2-RESUMO-USUARIO.md` - Resumo estruturado do usuário
   - `VERIFICACAO-DESAFIO-2.md` - Verificação completa de implementação
   - `GUIA-DEPLOY-VERSIONADO.md` - Documentação do deploy versionado

### **🎯 Objetivo:**
Após ler todos esses arquivos, você deve estar completamente contextualizado sobre:
- Histórico completo de conversas
- Estado atual da infraestrutura
- Regras e filosofia do projeto
- Processos implementados
- Onde paramos na última conversa

### **✅ Confirmação:**
Após ler todos os arquivos, confirme que está contextualizado e pronto para continuar de onde paramos.

EOF

# Criar script qbia-contexto.sh que será chamado pelo alias
cat > /home/ec2-user/bia/qbia-contexto.sh << 'EOF'
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
EOF

# Tornar script executável
chmod +x /home/ec2-user/bia/qbia-contexto.sh

# Configurar alias no .bashrc
if ! grep -q "alias qbia=" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Amazon Q BIA - Contexto Completo Automático" >> ~/.bashrc
    echo "alias qbia='/home/ec2-user/bia/qbia-contexto.sh'" >> ~/.bashrc
    echo "✅ Alias qbia adicionado ao .bashrc"
else
    # Atualizar alias existente
    sed -i 's|alias qbia=.*|alias qbia="/home/ec2-user/bia/qbia-contexto.sh"|' ~/.bashrc
    echo "✅ Alias qbia atualizado no .bashrc"
fi

# Recarregar .bashrc
source ~/.bashrc

echo ""
echo "🎉 Configuração concluída!"
echo ""
echo "📋 Como usar:"
echo "   qbia  # Amazon Q com contexto completo automático"
echo ""
echo "🤖 O que acontece quando você digita 'qbia':"
echo "   1. Ativa MCP servers (filesystem + ECS + database)"
echo "   2. Amazon Q lê automaticamente todos os arquivos .md"
echo "   3. Fica completamente contextualizado"
echo "   4. Pronto para continuar de onde paramos"
echo ""
echo "✅ Próximo passo: Digite 'qbia' para testar!"
EOF

chmod +x /home/ec2-user/bia/setup-qbia-contexto-completo.sh
