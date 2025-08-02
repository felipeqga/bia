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
- **Task Definition:** task-def-bia-alb:10
- **Load Balancer:** bia-1433396588.us-east-1.elb.amazonaws.com
- **RDS Instance:** bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
- **ECR Repository:** 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia

#### Arquitetura de Rede
**Instâncias EC2:**
1. **bia-dev** - Instância de desenvolvimento (onde Amazon Q roda)
2. **bia-ecs-instance-1a-v2** - Criada pelo ECS Cluster (us-east-1a, t3.micro)
3. **bia-ecs-instance-1b-v2** - Criada pelo ECS Cluster (us-east-1b, t3.micro)

**Fluxo de Tráfego:**
```
Internet → ALB → Target Group → 2 ECS Instances → ECS Tasks (containers)
```

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

### Otimizações de Performance Aplicadas

#### Configurações Otimizadas

**1. Target Group - Health Check:**
- **Interval:** 30s → 10s (3x mais rápido)
- **Timeout:** 5s (mantido)
- **Threshold:** 2 checks (mantido)
- **Tempo mínimo para healthy:** 60s → 20s

**2. Target Group - Deregistration Delay:**
- **Delay:** 30s → 5s (6x mais rápido)
- **Justificativa:** Aplicação stateless, sem sessões longas

**3. ECS Service - Deployment Configuration:**
- **minimumHealthyPercent:** 50% (mantido)
- **maximumPercent:** 100% → 200% (deploy paralelo)
- **Resultado:** 4 tasks simultâneas durante deploy

#### Impacto das Otimizações

| Configuração | Antes | Depois | Melhoria |
|-------------|-------|--------|----------|
| **Health Check** | 30s interval | 10s interval | 3x mais rápido |
| **Health Check Total** | 60s mínimo | 20s mínimo | 3x mais rápido |
| **Deregistration** | 30s delay | 5s delay | 6x mais rápido |
| **Deploy Strategy** | Sequencial | Paralelo | 2x mais rápido |
| **Tempo Total Esperado** | ~10 minutos | ~2 minutos | 80% redução |

### Pontos de Atenção

#### Resolvidos
1. **Permissões ECR:** ✅ Adicionada policy AmazonEC2ContainerRegistryPowerUser
2. **Deploy Automatizado:** ✅ CodePipeline funcionando
3. **Infraestrutura:** ✅ Todos os componentes AWS operacionais
4. **Performance:** ✅ Deploy otimizado para alta velocidade

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
4. **Health Checks:** Implementar health checks mais específicos da aplicação

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

### Problema: Deploy muito lento
**Sintomas:** Deploy levando mais de 5 minutos

**Soluções aplicadas:**
- Health Check interval reduzido para 10s
- Deregistration delay reduzido para 5s
- maximumPercent aumentado para 200%

---

## Rolling Update Otimizado

### Configuração Final
```json
{
  "minimumHealthyPercent": 50,
  "maximumPercent": 200,
  "strategy": "ROLLING"
}
```

### Fluxo do Deploy
1. **Estado inicial:** 2 tasks antigas rodando
2. **Deploy inicia:** Cria 2 tasks novas simultaneamente
3. **Estado temporário:** 4 tasks rodando (alta disponibilidade)
4. **Health check:** 20s para tasks ficarem healthy
5. **Deregistration:** 5s para remover tasks antigas
6. **Estado final:** 2 tasks novas rodando

### Benefícios
- **Zero downtime:** Sempre mantém pelo menos 1 task
- **Alta disponibilidade:** 4 tasks durante deploy
- **Deploy rápido:** Processo paralelo em vez de sequencial
- **Rollback seguro:** Tasks antigas mantidas até confirmação

---

*Última atualização: 02/08/2025 04:47 UTC*
*Otimizações de performance aplicadas e testadas*