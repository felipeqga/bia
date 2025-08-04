#!/bin/bash

# Script OTIMIZADO para criar pacote do DESAFIO-3 para compartilhamento
# Versão: Pós-sucesso (sem arquivos obsoletos)
# Criado em: 04/08/2025

echo "🎯 Criando pacote DESAFIO-3 OTIMIZADO para compartilhamento..."

# Limpar diretório anterior
rm -rf /tmp/bia-desafio-3-otimizado

# Criar diretório temporário
mkdir -p /tmp/bia-desafio-3-otimizado

# Copiar arquivos essenciais
echo "📦 Copiando arquivos essenciais..."

# Build e Deploy
cp Dockerfile /tmp/bia-desafio-3-otimizado/
cp buildspec.yml /tmp/bia-desafio-3-otimizado/
cp package.json /tmp/bia-desafio-3-otimizado/
cp package-lock.json /tmp/bia-desafio-3-otimizado/
cp deploy-versioned-alb.sh /tmp/bia-desafio-3-otimizado/

# Aplicação
cp server.js /tmp/bia-desafio-3-otimizado/
cp index.js /tmp/bia-desafio-3-otimizado/
cp -r api/ /tmp/bia-desafio-3-otimizado/
cp -r client/ /tmp/bia-desafio-3-otimizado/
cp -r config/ /tmp/bia-desafio-3-otimizado/
cp -r database/ /tmp/bia-desafio-3-otimizado/
cp -r lib/ /tmp/bia-desafio-3-otimizado/

# Configuração
cp .sequelizerc /tmp/bia-desafio-3-otimizado/
cp .dockerignore /tmp/bia-desafio-3-otimizado/
cp compose.yml /tmp/bia-desafio-3-otimizado/

# Scripts auxiliares
mkdir -p /tmp/bia-desafio-3-otimizado/scripts/ecs/unix/
cp scripts/ecs/unix/check-disponibilidade.sh /tmp/bia-desafio-3-otimizado/scripts/ecs/unix/
cp Dockerfile_checkdisponibilidade /tmp/bia-desafio-3-otimizado/
cp monitor-deploy.sh /tmp/bia-desafio-3-otimizado/

# Documentação OTIMIZADA (apenas o essencial)
cp README.md /tmp/bia-desafio-3-otimizado/
cp guia-desafio-3-corrigido.md /tmp/bia-desafio-3-otimizado/
cp historico-desafio-3-zero-downtime.md /tmp/bia-desafio-3-otimizado/
cp GUIA-DEPLOY-VERSIONADO.md /tmp/bia-desafio-3-otimizado/

# Apenas 1 arquivo técnico relevante
mkdir -p /tmp/bia-desafio-3-otimizado/.amazonq/context/
cp .amazonq/context/desafio-3-ecs-alb.md /tmp/bia-desafio-3-otimizado/.amazonq/context/

# Criar arquivo de instruções
cat > /tmp/bia-desafio-3-otimizado/INSTRUCOES-PERSONALIZACAO.md << 'EOF'
# 🎯 INSTRUÇÕES PARA PERSONALIZAR O DESAFIO-3

## ⚠️ ARQUIVOS QUE VOCÊ DEVE ALTERAR:

### 1. buildspec.yml
- Linha 7: Altere `387678648422.dkr.ecr.us-east-1.amazonaws.com` para seu Account ID
- Linha 8: Altere a região se necessário

### 2. deploy-versioned-alb.sh
- Linha 8: `ECR_REGISTRY` - Seu Account ID
- Linha 13: `ALB_DNS` - DNS do seu ALB (após criar)

### 3. Dockerfile (se usar ALB)
- Linha com `VITE_API_URL` - DNS do seu ALB

## 🚀 SEQUÊNCIA DE IMPLEMENTAÇÃO:

1. **Criar infraestrutura AWS** (seguir guia-desafio-3-corrigido.md)
2. **Personalizar arquivos** conforme acima
3. **Fazer primeiro deploy** com deploy-versioned-alb.sh
4. **Testar zero downtime** com monitor-deploy.sh

## 📚 DOCUMENTAÇÃO ESSENCIAL:
- `guia-desafio-3-corrigido.md` - Guia completo passo a passo
- `historico-desafio-3-zero-downtime.md` - Validação de zero downtime COMPROVADA
- `.amazonq/context/desafio-3-ecs-alb.md` - Guia técnico + correções críticas
- `GUIA-DEPLOY-VERSIONADO.md` - Sistema de deploy versionado
- `README.md` - Informações básicas do projeto

## 🎉 RESULTADO ESPERADO:
- ✅ Zero downtime durante deploys
- ✅ Rolling updates funcionais
- ✅ Capacity Provider equivalente ao Console AWS
- ✅ Deploy versionado com rollback

Boa sorte! 🚀
EOF

# Criar arquivo .gitignore para o pacote
cat > /tmp/bia-desafio-3-otimizado/.gitignore << 'EOF'
node_modules/
.env
.last-deployed-image
monitor-output.log
*.log
.DS_Store
EOF

# Criar tarball
cd /tmp
tar -czf bia-desafio-3-otimizado-$(date +%Y%m%d).tar.gz bia-desafio-3-otimizado/

echo "✅ Pacote OTIMIZADO criado: /tmp/bia-desafio-3-otimizado-$(date +%Y%m%d).tar.gz"
echo "📦 Tamanho do pacote:"
ls -lh /tmp/bia-desafio-3-otimizado-$(date +%Y%m%d).tar.gz

echo ""
echo "🎯 CONTEÚDO DO PACOTE OTIMIZADO:"
echo "- Aplicação completa (React + Node.js)"
echo "- Dockerfile e buildspec.yml"
echo "- Scripts de deploy versionado"
echo "- Scripts de monitoramento"
echo "- Documentação ESSENCIAL (sem redundâncias)"
echo "- Instruções de personalização"

echo ""
echo "📋 ARQUIVOS REMOVIDOS (obsoletos):"
echo "❌ DESAFIO-3-RESUMO-USUARIO.md (obsoleto)"
echo "❌ VERIFICACAO-DESAFIO-3.md (desatualizado)"
echo "❌ ATUALIZACAO-DESAFIO-3-COMPLETA.md (redundante)"
echo "❌ troubleshooting-ecs-alb.md (problemas resolvidos)"
echo "❌ erros-criacao-cluster-ecs.md (erros superados)"

echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Copie o arquivo .tar.gz para onde precisar"
echo "2. Extraia: tar -xzf bia-desafio-3-otimizado-YYYYMMDD.tar.gz"
echo "3. Leia INSTRUCOES-PERSONALIZACAO.md"
echo "4. Siga o guia-desafio-3-corrigido.md"