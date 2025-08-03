# Configuração do CodePipeline - Projeto BIA

## PASSO-7: Criação do CodePipeline

### Configurações Iniciais
1. **Seleciona:** Build custom pipeline

### Choose pipeline settings
- **Pipeline name:** `bia`
- **Execution mode:** Superseded
- **Service role:** New service role

### Source Configuration
- **Source provider:** GitHub APP
- **Ação:** Clica no botão "Connect to GitHub" para se conectar à sua conta e digita as credenciais

### Add source stage
- **Repository name:** `felipeqga/bia`
- **Default branch:** `main`
- **Output artifact format:** CodePipeline default

### Webhook Configuration
- **Webhook - optional**
- **MARCA:** Start your pipeline on push and pull request events

### Build Configuration
- **Build provider:** AWS CODE BUILD

### Create build project
- **Project name:** `bia-build-pipeline`

### Buildspec Configuration
- **Use a buildspec file:** `buildspec.yml`
- **⚠️ IMPORTANTE:** Não esquecer de alterar os parâmetros de ECR dentro do arquivo

### Troubleshooting
- **OBS:** Se ao criar der um erro de POLICY, é só deletar a policy com o nome que aparecer no erro

### Step 4 - Add build stage
- **Ação:** AVANÇA deixa padrão

### Step 5 - Add deploy stage
- **Deploy provider:** Amazon ECS
- **Cluster name:** `cluster-bia-alb`
- **Service name:** `service-bia-alb`

### ⚠️ IMPORTANTE
**Não criar o CodePipeline ainda** - aguardar comando específico para criação.

---

## Configurações Pós-Criação

### Variáveis de Ambiente do CodeBuild
Após criar o pipeline, configurar as variáveis de ambiente:

```bash
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

### Verificação do Pipeline
```bash
# Verificar status do pipeline
aws codepipeline get-pipeline-state --name bia

# Verificar execuções do pipeline
aws codepipeline list-pipeline-executions --pipeline-name bia
```

---

## Estrutura Final do Pipeline

### Stages
1. **Source:** GitHub (felipeqga/bia)
2. **Build:** CodeBuild (bia-build-pipeline)
3. **Deploy:** ECS (cluster-bia-alb/service-bia-alb)

### Triggers
- Push para branch `main`
- Pull requests (opcional)

### Artifacts
- Source code do GitHub
- Docker image no ECR
- Deploy para ECS

---

*Configuração baseada nas especificações do DESAFIO-3*
*Pipeline integrado com infraestrutura ECS + ALB existente*
