# Script de Deploy Versionado - Projeto BIA

## 🎯 **Visão Geral**

O script `deploy-versioned.sh` é uma solução completa para deploy com versionamento automático e capacidade de rollback. Criado seguindo a filosofia de simplicidade do projeto BIA.

## 📋 **Funcionalidades**

### ✅ **Deploy Automático**
- Tag baseada em timestamp (YYYYMMDD-HHMMSS)
- Build e push para ECR com versionamento
- Deploy no ECS com verificação de estabilidade
- Backup automático da versão anterior

### ✅ **Rollback Inteligente**
- **Automático:** Volta para versão imediatamente anterior
- **Manual:** Volta para qualquer tag específica
- **Seguro:** Verifica existência da tag antes do rollback
- **Backup:** Salva versão atual antes de qualquer mudança

### ✅ **Monitoramento**
- Status da aplicação em tempo real
- Lista das últimas 10 versões no ECR
- URL da aplicação e health check
- Informações detalhadas do ECS

---

## 🚀 **Como Usar**

### **1. Deploy de Nova Versão**

```bash
cd /home/ec2-user/bia
./deploy-versioned.sh deploy
```

**O que acontece:**
1. 🏷️ Gera tag automática: `v20250731-224437`
2. 💾 Salva versão atual como backup
3. 🔐 Login no ECR
4. 🏗️ Build da imagem Docker
5. 📤 Push para ECR com tag versionada
6. 🚀 Deploy no ECS
7. ⏳ Aguarda estabilização
8. 📊 Mostra status final

**Exemplo de saída:**
```
🚀 Iniciando deploy versionado - Tag: v20250731-224437
🔐 Fazendo login no ECR...
🏗️ Fazendo build da imagem com tag: v20250731-224437
📤 Fazendo push para ECR...
✅ Imagem v20250731-224437 enviada com sucesso!
🚀 Iniciando deploy da versão: v20250731-224437
💾 Imagem atual salva: 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest
⏳ Aguardando deployment estabilizar...
✅ Deploy da versão v20250731-224437 concluído com sucesso!
🎉 Deploy concluído! Versão: v20250731-224437
```

### **2. Rollback Automático**

```bash
./deploy-versioned.sh rollback
```

**O que acontece:**
1. 📖 Lê arquivo `.last-deployed-image`
2. 🔄 Volta para versão anterior automaticamente
3. 📋 Cria nova task definition
4. 🔄 Atualiza service ECS
5. ⏳ Aguarda estabilização
6. ✅ Confirma rollback

**Quando usar:**
- Após um deploy que deu problema
- Quando quiser desfazer a última mudança
- Para voltar rapidamente sem especificar tag

### **3. Rollback Manual**

```bash
./deploy-versioned.sh rollback v20250731-120000
```

**O que acontece:**
1. ✅ Verifica se a tag existe no ECR
2. 💾 Salva versão atual como backup
3. 🔄 Deploy da versão especificada
4. ⏳ Aguarda estabilização
5. ✅ Confirma rollback

**Quando usar:**
- Para voltar para versão específica
- Quando souber exatamente qual versão quer
- Para testar versões antigas

### **4. Listar Versões**

```bash
./deploy-versioned.sh list
```

**Saída exemplo:**
```
📋 Últimas 10 imagens no ECR:
+------------------+---------------------------------------------------------------------------+------------------------------------+
|  v20250731-224437|  sha256:e05218101388583d57d3c6b6bac30f87e627696706c1840170904fef1e7eefd1  |  2025-07-31T22:44:51.192000+00:00  |
|  v20250731-180000|  sha256:f77344c7b2a5ca96cfbf1f3eff3a25cad4a3de7b4463d31c55c070b7aa58cebb  |  2025-07-31T18:47:56.232000+00:00  |
|  v20250731-120000|  sha256:aa8b7931c3ed9468d63100527877c0613814810b597afaf213c08e35fe75f7ef  |  2025-07-31T16:46:37.969000+00:00  |
+------------------+---------------------------------------------------------------------------+------------------------------------+
```

**Quando usar:**
- Antes de fazer rollback manual
- Para ver histórico de versões
- Para identificar tags disponíveis

### **5. Status da Aplicação**

```bash
./deploy-versioned.sh status
```

**Saída exemplo:**
```
📊 Status atual da aplicação:
🖼️ Imagem atual: 387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest
🔄 Status do service: ACTIVE
▶️ Tasks rodando: 1
🌐 URL da aplicação: http://44.203.21.88
🔍 Health check: http://44.203.21.88/api/versao
```

**Quando usar:**
- Para verificar se aplicação está funcionando
- Após deploy ou rollback
- Para obter URL da aplicação
- Para troubleshooting

---

## 🎯 **Exemplo Prático - Mudança no Botão**

### **Cenário Real:** Alterar botão de "Adicionar Tarefa" para "Add Tarefa: AmazonQ"

#### **Passo 1: Fazer mudança no código**
```bash
# Arquivo: client/src/components/AddTask.jsx
# Linha 62: "Adicionar Tarefa" → "Add Tarefa: AmazonQ"
```

#### **Passo 2: Deploy da mudança**
```bash
./deploy-versioned.sh deploy
```
**Resultado:**
- ✅ Tag: `v20250731-224437`
- ✅ Build e push realizados
- ✅ Deploy no ECS concluído
- ✅ Aplicação atualizada

#### **Passo 3: Testar mudança**
```bash
# Verificar se aplicação está funcionando
curl http://44.203.21.88/api/versao

# Acessar no navegador
# http://44.203.21.88
```

#### **Passo 4: Se não gostar da mudança**
```bash
# Rollback automático (volta 1 versão)
./deploy-versioned.sh rollback
```
**Resultado:**
- ✅ Volta para versão anterior
- ✅ Botão volta a ser "Adicionar Tarefa"

#### **Passo 5: Se quiser versão específica**
```bash
# Listar versões disponíveis
./deploy-versioned.sh list

# Rollback para versão específica
./deploy-versioned.sh rollback v20250731-120000
```

---

## 🔧 **Como Funciona Internamente**

### **Versionamento**
- **Formato da tag:** `v20250731-224437` (v + YYYYMMDD-HHMMSS)
- **Geração:** `date +'%Y%m%d-%H%M%S'`
- **Armazenamento:** ECR com múltiplas tags por imagem

### **Backup Automático**
- **Arquivo:** `.last-deployed-image`
- **Conteúdo:** URI completa da imagem anterior
- **Uso:** Rollback automático
- **Localização:** Raiz do projeto

### **Task Definition**
- **Processo:** Cria nova task definition para cada deploy/rollback
- **Campos removidos:** ARN, revision, status (campos read-only)
- **Atualização:** Apenas imagem é alterada
- **Limpeza:** Arquivos temporários removidos automaticamente

### **Verificações de Segurança**
- **Existência da tag:** Verifica no ECR antes do rollback
- **Estabilidade:** Aguarda service estabilizar antes de confirmar
- **Backup:** Sempre salva versão atual antes de mudanças

---

## 📊 **Estrutura de Arquivos**

### **Arquivos Principais**
```
/home/ec2-user/bia/
├── deploy-versioned.sh          # Script principal ✅
├── .last-deployed-image         # Backup automático
├── temp_task_def.json          # Temporário (removido após uso)
└── rollback_task_def.json      # Temporário (removido após uso)
```

### **Configurações do Script**
```bash
ECR_REGISTRY="387678648422.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY="bia"
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
REGION="us-east-1"
```

---

## ⚠️ **Troubleshooting**

### **Problema: Deploy falha no build**
```bash
# Verificar sintaxe do Dockerfile
docker build -t test .

# Verificar logs detalhados
./deploy-versioned.sh deploy 2>&1 | tee deploy.log
```

### **Problema: Rollback não funciona**
```bash
# Verificar se arquivo de backup existe
ls -la .last-deployed-image

# Ver conteúdo do backup
cat .last-deployed-image

# Listar versões disponíveis
./deploy-versioned.sh list

# Rollback manual
./deploy-versioned.sh rollback v20250731-120000
```

### **Problema: Aplicação não responde após deploy**
```bash
# Verificar status
./deploy-versioned.sh status

# Testar health check
curl http://44.203.21.88/api/versao

# Verificar tasks ECS
aws ecs describe-services --cluster cluster-bia --services service-bia --region us-east-1

# Fazer rollback se necessário
./deploy-versioned.sh rollback
```

### **Problema: Tag não encontrada**
```bash
# Listar todas as tags disponíveis
./deploy-versioned.sh list

# Verificar no ECR
aws ecr describe-images --repository-name bia --region us-east-1

# Usar tag existente
./deploy-versioned.sh rollback v20250731-224437
```

---

## 🎯 **Boas Práticas**

### **✅ Antes do Deploy**
1. **Testar localmente:** Verificar se aplicação compila
2. **Verificar mudanças:** Confirmar que alterações estão corretas
3. **Backup manual:** Anotar versão atual se necessário

### **✅ Durante o Deploy**
1. **Aguardar conclusão:** Não interromper o processo
2. **Monitorar logs:** Verificar se não há erros
3. **Verificar estabilização:** Aguardar confirmação de sucesso

### **✅ Após o Deploy**
1. **Testar aplicação:** Verificar se está funcionando
2. **Testar mudanças:** Confirmar que alterações estão visíveis
3. **Manter backup:** Não remover `.last-deployed-image`

### **✅ Para Rollback**
1. **Identificar problema:** Confirmar que rollback é necessário
2. **Escolher método:** Automático vs manual
3. **Verificar resultado:** Testar após rollback

---

## 📈 **Vantagens do Sistema**

### **🚀 Velocidade**
- Deploy automatizado em ~2 minutos
- Rollback em ~1 minuto
- Sem intervenção manual necessária

### **🛡️ Segurança**
- Backup automático antes de mudanças
- Verificações de existência de tags
- Aguarda estabilização antes de confirmar

### **📊 Rastreabilidade**
- Versionamento baseado em timestamp
- Histórico completo no ECR
- Logs detalhados de cada operação

### **🎯 Simplicidade**
- Um comando por ação
- Feedback visual claro
- Documentação integrada (help)

---

## 🎉 **Resultado Atual**

### **✅ Sistema Implementado**
- **Script:** `deploy-versioned.sh` funcionando
- **Versão atual:** `v20250731-224437`
- **Mudança deployada:** Botão "Add Tarefa: AmazonQ"
- **Aplicação:** http://44.203.21.88 ✅

### **🔄 Rollback Disponível**
```bash
# Para desfazer a mudança do botão
./deploy-versioned.sh rollback
```

### **📋 Próximos Usos**
1. **Novas mudanças:** `./deploy-versioned.sh deploy`
2. **Rollback se necessário:** `./deploy-versioned.sh rollback`
3. **Monitoramento:** `./deploy-versioned.sh status`

---

**Criado em:** 31/07/2025 22:46 UTC  
**Primeira versão:** v20250731-224437  
**Status:** ✅ Funcionando perfeitamente  
**Aplicação:** http://44.203.21.88
