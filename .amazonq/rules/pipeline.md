# Regras de Pipeline - Projeto BIA

## Definição de Pipeline
Sempre que falarmos de **pipeline** para este projeto, estamos nos referindo à combinação de:
- **AWS CodePipeline** (orquestração)
- **AWS CodeBuild** (build e deploy)

## ⚠️ **REGRA CRÍTICA: LEIA A DOCUMENTAÇÃO PRIMEIRO**
**SEMPRE consultar a documentação de troubleshooting ANTES de inventar soluções!**
- Arquivo principal: `.amazonq/context/codepipeline-troubleshooting-permissions.md`
- Comparação de roles: `.amazonq/context/codepipeline-roles-comparison.md`
- **Erro #1:** GitHub Connection (`codestar-connections:UseConnection`)
- **Processo:** Documentação → Aplicar solução → Testar

## Arquitetura do Pipeline

### Componentes Principais
1. **Source Stage:** GitHub como repositório de código
2. **Build Stage:** CodeBuild para build da aplicação
3. **Deploy Stage:** Deploy automático para ECS

### Configuração Base
- **Buildspec:** Já configurado no arquivo `buildspec.yml` na raiz do projeto
- **ECR:** Registry para armazenar imagens Docker
- **ECS:** Target de deploy da aplicação

## Fluxo do Pipeline

### 1. Source (GitHub)
- Trigger automático em push para branch principal
- Webhook configurado para detectar mudanças

### 2. Build (CodeBuild)
- Executa comandos definidos no `buildspec.yml`
- Build da imagem Docker
- Push da imagem para ECR

### 3. Deploy (ECS)
- Deploy automático da nova imagem
- Rolling update do serviço ECS
- Health check da aplicação

## Configurações Importantes

### Nomenclatura do Projeto CodeBuild
- **Nome correto:** `bia-build-pipeline` (não bia-build)
- **Buildspec:** `buildspec.yml` na raiz do projeto
- **⚠️ Importante:** Alterar parâmetros de ECR no buildspec.yml

### Variáveis de Ambiente
- Configuradas no CodeBuild project
- Variáveis específicas por ambiente (dev/prod)

#### Configuração de Variáveis no CodeBuild
```bash
# Adicionar variáveis de ambiente no projeto CodeBuild
aws codebuild update-project --name bia-build-pipeline --environment '{
  "type": "LINUX_CONTAINER",
  "image": "aws/codebuild/amazonlinux2-x86_64-standard:3.0",
  "computeType": "BUILD_GENERAL1_MEDIUM",
  "environmentVariables": [
    {"name": "DB_HOST", "value": "bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com"},
    {"name": "DB_USER", "value": "postgres"},
    {"name": "DB_PWD", "value": "Kgegwlaj6mAIxzHaEqgo"},
    {"name": "DB_PORT", "value": "5432"},
    {"name": "NODE_ENV", "value": "production"}
  ]
}'
```

### Permissões IAM
- Role do CodeBuild com permissões para:
  - ECR (push/pull de imagens)
  - ECS (deploy de serviços)

### Monitoramento
- CloudWatch Logs para logs do build
- Métricas de build e deploy

## Boas Práticas

### Performance
- Cache de dependências do npm
- Otimização de layers do Docker

### Confiabilidade
- Health checks após deploy
- Rollback automático em caso de falha

## Troubleshooting Comum

### **🚨 ORDEM PREVISÍVEL DE ERROS:**
1. **GitHub Connection** (`codestar-connections:UseConnection`) - MAIS COMUM
2. **CodeBuild StartBuild** (permissões CodeBuild na role do CodePipeline)
3. **ECR Login** (permissões ECR na role do CodeBuild)
4. **ECS Service Not Found** (service deve existir antes do deploy)
5. **PassRole** (se necessário)

### **✅ PROCESSO CORRETO:**
1. **Verificar logs** do pipeline no Console AWS
2. **Consultar documentação** de troubleshooting
3. **Aplicar solução específica** para o erro
4. **Usar "Retry Stage"** em vez de recriar pipeline
5. **Não inventar soluções** - usar o que já foi testado

### Build Failures
- Verificar logs no CloudWatch
- Validar permissões IAM
- Confirmar configuração do buildspec.yml

### Deploy Issues
- Verificar health checks do ECS
- Validar configuração do service
- Confirmar conectividade com RDS

### **❌ ERROS COMUNS A EVITAR:**
- Usar `codeconnections` em vez de `codestar-connections`
- Over-engineering com permissões excessivas
- Recriar pipeline em vez de usar "Retry Stage"
- Ignorar a documentação existente

## Evolução do Pipeline

### Fase Inicial
- Pipeline simples: Source → Build → Deploy
- Deploy direto para ECS

### Fase Avançada
- Múltiplos ambientes (dev/staging/prod)
- Aprovações manuais para produção

## 🎯 **LIÇÕES APRENDIDAS (07/08/2025)**

### **✅ DESCOBERTAS VALIDADAS:**
1. **GitHub Connection é o erro #1** - sempre verificar primeiro
2. **Documentação deve ser consultada PRIMEIRO** antes de inventar soluções
3. **Retry Stage é mais eficiente** que recriar pipeline
4. **Permissões mínimas funcionam** tão bem quanto permissões amplas
5. **Over-engineering não melhora performance** - apenas adiciona complexidade
6. **Ordem dos erros é previsível:** GitHub → CodeBuild → ECS

### **🔧 REGRAS PARA AMAZON Q:**
- **SEMPRE** ler documentação completa antes de agir
- **NUNCA** inventar soluções quando já existem documentadas
- **PRESTAR ATENÇÃO** quando usuário menciona "já implementamos"
- **USAR** soluções testadas em vez de experimentar
- **SIMPLICIDADE** > Complexidade
