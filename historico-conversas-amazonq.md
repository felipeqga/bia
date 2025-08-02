# Histórico de Conversas - Amazon Q

## Data: 02/08/2025

### Sessão: Deploy e Troubleshooting com CodePipeline

#### Contexto Inicial
- Aplicação BIA com problemas de conectividade com banco RDS
- Endpoint `/api/versao` funcionando, retornando "Bia 4.2.0"
- Endpoint `/api/usuarios` retornando HTML em vez de JSON
- Infraestrutura AWS: ECS + ALB + RDS funcionando corretamente

#### Problemas Identificados e Soluções

**1. Deploy Manual Executado**
- Executado deploy versioned com sucesso: `v20250802-040807`
- Task definition 9 criada com variáveis de ambiente corretas:
  - DB_HOST: bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com
  - DB_USER: postgres
  - DB_PWD: Kgegwlaj6mAIxzHaEqgo
  - DB_PORT: 5432

**2. CodePipeline Habilitado**
- Usuário habilitou CodePipeline para automação de deploy
- Problema de permissões ECR resolvido: adicionada policy `AmazonEC2ContainerRegistryPowerUser` à role `codebuild-bia-build-pipeline-service-role`
- Erro original: `aws ecr get-login-password` falhando por falta de permissões

**3. Problema Pós-CodePipeline**
- Após habilitar CodePipeline, aplicação perdeu conectividade com banco
- Análise revelou que CodePipeline executou novo deploy (04:19:56) sobrescrevendo deploy manual (04:16:04)
- **Causa raiz**: buildspec.yml não inclui variáveis de ambiente do banco

#### Análise do buildspec.yml
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo Fazendo login no ECR...      
      - aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 387678648422.dkr.ecr.us-east-1.amazonaws.com
      - REPOSITORY_URI=387678648422.dkr.ecr.us-east-1.amazonaws.com/bia
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build iniciado em `date`
      - echo Gerando imagem da BIA...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build finalizado com sucesso em `date`
      - echo Fazendo push da imagem para o ECR...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo Gerando artefato da imagem para o ECS
      - printf '[{"name":"bia","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files: imagedefinitions.json
```

**Problema identificado**: O buildspec.yml gera apenas `imagedefinitions.json` com a nova imagem, mas não preserva as variáveis de ambiente do banco de dados.

#### Soluções Propostas
1. **Configurar variáveis no CodeBuild** - Adicionar DB_HOST, DB_USER, DB_PWD, DB_PORT como environment variables
2. **Modificar buildspec.yml** - Para gerar task definition completa
3. **Usar Parameter Store** - Para credenciais seguras

#### Alteração Realizada
- Modificado botão da aplicação de "Add Tarefa: AmazonQ" para "Add Tarefa: CodePipeLine"
- Arquivo alterado: `/client/src/components/AddTask.jsx`

#### Status Atual
- **Infraestrutura**: ✅ Funcionando (ECS, ALB, RDS, Security Groups)
- **CodePipeline**: ✅ Funcionando (com permissões ECR corrigidas)
- **Deploy**: ✅ Executando automaticamente
- **Conectividade DB**: ❌ Perdida após CodePipeline (variáveis de ambiente não configuradas)
- **Próximo passo**: Configurar variáveis de ambiente no CodeBuild

#### Informações Técnicas
- **Cluster ECS**: cluster-bia-alb
- **Service**: service-bia-alb
- **Task Definition**: task-def-bia-alb:9
- **Load Balancer**: bia-1433396588.us-east-1.elb.amazonaws.com
- **ECR Repository**: 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia
- **RDS Instance**: bia.cgxkkc8ecg1q.us-east-1.rds.amazonaws.com

#### Lições Aprendidas
1. CodePipeline pode sobrescrever configurações manuais se não estiver adequadamente configurado
2. Variáveis de ambiente devem ser configuradas no CodeBuild ou na task definition template
3. Permissões ECR são essenciais para funcionamento do pipeline
4. Monitoramento de deployments é crucial para identificar quando automação sobrescreve configurações manuais

---

## Comandos Úteis Executados

### AWS CLI
```bash
# Verificar serviço ECS
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb

# Verificar task definition
aws ecs describe-task-definition --task-definition task-def-bia-alb

# Listar task definitions
aws ecs list-task-definitions --family-prefix task-def-bia-alb --sort DESC

# Testar conectividade
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/api/versao
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/api/usuarios
```

### Deploy Script
```bash
./deploy-versioned-alb.sh deploy
```

---

*Histórico salvo em: 02/08/2025 04:20 UTC*