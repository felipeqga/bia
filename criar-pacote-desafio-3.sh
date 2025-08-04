#!/bin/bash

# Script para criar pacote do DESAFIO-3 para compartilhamento
# Criado em: 03/08/2025

echo "🎯 Criando pacote DESAFIO-3 para compartilhamento..."

# Criar diretório temporário
mkdir -p /tmp/bia-desafio-3

# Copiar arquivos essenciais
echo "📦 Copiando arquivos essenciais..."

# Build e Deploy
cp Dockerfile /tmp/bia-desafio-3/
cp buildspec.yml /tmp/bia-desafio-3/
cp package.json /tmp/bia-desafio-3/
cp package-lock.json /tmp/bia-desafio-3/
cp deploy-versioned-alb.sh /tmp/bia-desafio-3/

# Aplicação
cp server.js /tmp/bia-desafio-3/
cp index.js /tmp/bia-desafio-3/
cp -r api/ /tmp/bia-desafio-3/
cp -r client/ /tmp/bia-desafio-3/
cp -r config/ /tmp/bia-desafio-3/
cp -r database/ /tmp/bia-desafio-3/
cp -r lib/ /tmp/bia-desafio-3/

# Configuração
cp .sequelizerc /tmp/bia-desafio-3/
cp .dockerignore /tmp/bia-desafio-3/
cp compose.yml /tmp/bia-desafio-3/

# Scripts auxiliares
mkdir -p /tmp/bia-desafio-3/scripts/ecs/unix/
cp scripts/ecs/unix/check-disponibilidade.sh /tmp/bia-desafio-3/scripts/ecs/unix/
cp Dockerfile_checkdisponibilidade /tmp/bia-desafio-3/
cp monitor-deploy.sh /tmp/bia-desafio-3/

# Documentação
cp README.md /tmp/bia-desafio-3/
cp guia-desafio-3-corrigido.md /tmp/bia-desafio-3/
cp historico-desafio-3-zero-downtime.md /tmp/bia-desafio-3/

# Documentação específica DESAFIO-3
mkdir -p /tmp/bia-desafio-3/.amazonq/context/
cp .amazonq/context/desafio-3-ecs-alb.md /tmp/bia-desafio-3/.amazonq/context/
cp .amazonq/context/troubleshooting-ecs-alb.md /tmp/bia-desafio-3/.amazonq/context/
cp .amazonq/context/erros-criacao-cluster-ecs.md /tmp/bia-desafio-3/.amazonq/context/
cp GUIA-DEPLOY-VERSIONADO.md /tmp/bia-desafio-3/

# Criar arquivo de instruções
cat > /tmp/bia-desafio-3/INSTRUCOES-PERSONALIZACAO.md << 'EOF'
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

## 📚 DOCUMENTAÇÃO:
- `guia-desafio-3-corrigido.md` - Guia completo passo a passo
- `historico-desafio-3-zero-downtime.md` - Validação de zero downtime
- `.amazonq/context/desafio-3-ecs-alb.md` - Guia técnico detalhado
- `.amazonq/context/troubleshooting-ecs-alb.md` - Troubleshooting específico
- `.amazonq/context/erros-criacao-cluster-ecs.md` - Erros comuns e soluções
- `GUIA-DEPLOY-VERSIONADO.md` - Sistema de deploy versionado
- `README.md` - Informações básicas do projeto

Boa sorte! 🎉
EOF

# Criar arquivo .gitignore para o pacote
cat > /tmp/bia-desafio-3/.gitignore << 'EOF'
node_modules/
.env
.last-deployed-image
monitor-output.log
*.log
.DS_Store
EOF

# Criar tarball
cd /tmp
tar -czf bia-desafio-3-$(date +%Y%m%d).tar.gz bia-desafio-3/

echo "✅ Pacote criado: /tmp/bia-desafio-3-$(date +%Y%m%d).tar.gz"
echo "📦 Tamanho do pacote:"
ls -lh /tmp/bia-desafio-3-$(date +%Y%m%d).tar.gz

echo ""
echo "🎯 CONTEÚDO DO PACOTE:"
echo "- Aplicação completa (React + Node.js)"
echo "- Dockerfile e buildspec.yml"
echo "- Scripts de deploy versionado"
echo "- Scripts de monitoramento"
echo "- Documentação completa"
echo "- Instruções de personalização"

echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Copie o arquivo .tar.gz para onde precisar"
echo "2. Extraia: tar -xzf bia-desafio-3-YYYYMMDD.tar.gz"
echo "3. Leia INSTRUCOES-PERSONALIZACAO.md"
echo "4. Siga o guia-desafio-3-corrigido.md"