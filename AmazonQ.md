# Projeto BIA - Contexto e Análise

## Visão Geral do Projeto
**Nome:** BIA  
**Versão:** 4.2.0  
**Período do Bootcamp:** 28/07 a 03/08/2025 (Online e ao Vivo às 20h)  
**Repositório:** https://github.com/henrylle/bia

## Impressões Iniciais do Desenvolvedor
O projeto da BIA é um projeto educacional criado pelo Henrylle Maia (@henryllemaia) para ser usado nos eventos que ele realiza e servir de base para o treinamento Formação AWS.

É um projeto concebido no ano de 2021 e que vem evoluindo usando as melhores práticas dentro da AWS.

O foco base dele é fornecer uma estrutura educacional em que o aluno possa evoluir gradualmente, desde problemas simples até situações mais complexas.

---

## Análise Técnica (Amazon Q)

### Arquitetura Identificada
- **Frontend:** React 17.0.2 com Vite para build
- **Backend:** Node.js com Express 4.17.1
- **Banco de Dados:** PostgreSQL 16.1
- **ORM:** Sequelize 6.6.5
- **Containerização:** Docker com Docker Compose
- **CI/CD:** AWS CodePipeline + CodeBuild
- **Infraestrutura:** ECS + ALB + RDS

### Stack Tecnológica
**Frontend:**
- React com React Router DOM
- React Icons para ícones
- Vite como bundler (configurado no Dockerfile)

**Backend:**
- Express.js como framework web
- Sequelize como ORM
- Morgan para logging
- CORS habilitado
- Express Session para gerenciamento de sessões
- EJS e HBS como template engines

**Infraestrutura:**
- Docker containerizado
- AWS SDK integrado (Secrets Manager, STS)
- PostgreSQL como banco principal
- Suporte a variáveis de ambiente
- ECS com Application Load Balancer
- CodePipeline para CI/CD automatizado

### Estrutura do Projeto
```
/bia
├── api/                 # APIs do backend
├── client/             # Aplicação React
├── config/             # Configurações
├── database/           # Migrations e seeds
├── scripts/            # Scripts auxiliares
├── tests/              # Testes unitários (Jest)
├── docs/               # Documentação
├── compose.yml         # Docker Compose
├── Dockerfile          # Container da aplicação
├── buildspec.yml       # AWS CodeBuild
└── package.json        # Dependências Node.js
```

### Recursos AWS Identificados
- **ECR:** Registry para imagens Docker (configurado no buildspec.yml)
- **CodeBuild:** Pipeline de CI/CD já configurado
- **CodePipeline:** Automação de deploy
- **ECS:** Orquestração de containers
- **ALB:** Application Load Balancer
- **RDS:** PostgreSQL gerenciado
- **Security Groups:** Controle de acesso de rede

### Estado Atual da Infraestrutura

#### Componentes Ativos
- **ECS Cluster:** cluster-bia-alb
- **ECS Service:** service-bia-alb (2 tasks rodando)
- **Task Definition:** task-def-bia-alb:9
- **Load Balancer:** bia-1433396588.us-east-1.elb.amazonaws.com
- **RDS Instance:** bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
- **ECR Repository:** 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia

#### Configurações de Rede
- **Security Groups:**
  - bia-db: Acesso ao RDS PostgreSQL (porta 5432)
  - bia-ec2: Instâncias ECS
  - bia-alb: Application Load Balancer (portas 80/443)

#### Variáveis de Ambiente (RDS)
- DB_HOST: bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
- DB_USER: postgres
- DB_PWD: Kgegwlaj6mAIxzHaEqgo
- DB_PORT: 5432
- NODE_ENV: production

### Pontos de Atenção

#### Resolvidos
1. **Permissões ECR:** ✅ Adicionada policy AmazonEC2ContainerRegistryPowerUser
2. **Deploy Automatizado:** ✅ CodePipeline funcionando
3. **Infraestrutura:** ✅ Todos os componentes AWS operacionais

#### Pendentes
1. **Variáveis de Ambiente:** ❌ CodeBuild não preserva variáveis do banco
2. **Buildspec.yml:** ❌ Precisa incluir configuração de environment variables
3. **Conectividade DB:** ❌ Perdida após deploy do CodePipeline

### Recomendações

#### Imediatas
1. **Configurar variáveis no CodeBuild:** Adicionar DB_HOST, DB_USER, DB_PWD, DB_PORT como environment variables no projeto CodeBuild
2. **Modificar buildspec.yml:** Para preservar configurações de ambiente
3. **Implementar Parameter Store:** Para gerenciamento seguro de credenciais

#### Futuras
1. **Monitoramento:** Implementar CloudWatch Logs e métricas
2. **Secrets Manager:** Migrar credenciais para gerenciamento seguro
3. **Multi-ambiente:** Configurar ambientes dev/staging/prod
4. **Health Checks:** Melhorar verificações de saúde da aplicação

---

## Troubleshooting Guide

### Problema: Aplicação não conecta ao banco após CodePipeline
**Sintomas:**
- `/api/versao` funciona (retorna "Bia 4.2.0")
- `/api/usuarios` retorna HTML em vez de JSON

**Causa:** CodePipeline não preserva variáveis de ambiente do banco

**Solução:** Configurar variáveis no CodeBuild ou modificar buildspec.yml

### Problema: ECR login falha no CodeBuild
**Sintomas:** `aws ecr get-login-password` retorna erro de permissão

**Solução:** Adicionar policy `AmazonEC2ContainerRegistryPowerUser` à role do CodeBuild

---

*Última atualização: 02/08/2025 04:20 UTC*