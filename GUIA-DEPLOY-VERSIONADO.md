# Guia de Deploy Versionado - Projeto BIA

## 🎯 **Visão Geral**

O sistema de deploy versionado permite fazer deployments seguros com capacidade de rollback automático ou manual. Cada deploy gera uma tag única baseada em timestamp (data/hora/segundo).

## 🚀 **Funcionalidades**

### **✅ Deploy Versionado**
- Tag automática: `v20250731-224437` (YYYYMMDD-HHMMSS)
- Backup automático da versão anterior
- Build e push para ECR com versionamento
- Deploy automático no ECS
- Verificação de estabilidade

### **🔄 Rollback Inteligente**
- **Rollback automático:** Volta para a versão imediatamente anterior
- **Rollback manual:** Volta para qualquer tag específica
- **Backup de segurança:** Salva versão atual antes do rollback
- **Verificação de existência:** Confirma se a tag existe no ECR

### **📊 Monitoramento**
- Status da aplicação em tempo real
- Lista das últimas 10 imagens no ECR
- URL da aplicação e health check
- Informações de tasks e service

## 📋 **Comandos Disponíveis**

### **1. Deploy (Nova Versão)**
```bash
./deploy-versioned.sh deploy
```
**O que faz:**
- Gera tag automática (ex: `v20250731-224437`)
- Salva versão atual como backup
- Faz build da imagem com as mudanças
- Push para ECR com tag versionada
- Deploy no ECS
- Aguarda estabilização
- Mostra status final

### **2. Rollback Automático**
```bash
./deploy-versioned.sh rollback
```
**O que faz:**
- Volta para a versão imediatamente anterior
- Usa o backup salvo no último deploy
- Cria nova task definition
- Atualiza o service
- Aguarda estabilização

### **3. Rollback Manual**
```bash
./deploy-versioned.sh rollback v20250731-120000
```
**O que faz:**
- Volta para a tag específica informada
- Verifica se a tag existe no ECR
- Salva versão atual como backup
- Deploy da versão especificada

### **4. Listar Versões**
```bash
./deploy-versioned.sh list
```
**O que faz:**
- Lista últimas 10 imagens no ECR
- Mostra tags, hash SHA256 e data de push
- Útil para escolher versão para rollback manual

### **5. Status da Aplicação**
```bash
./deploy-versioned.sh status
```
**O que faz:**
- Mostra imagem atual em uso
- Status do service ECS
- Número de tasks rodando
- URL da aplicação
- Endpoint de health check

### **6. Ajuda**
```bash
./deploy-versioned.sh help
```

## 🎯 **Exemplo Prático - Mudança no Botão**

### **Cenário:** Alterar botão de "Adicionar Tarefa" para "Add Tarefa: AmazonQ"

#### **Passo 1: Fazer a mudança no código**
```bash
# Arquivo alterado: client/src/components/AddTask.jsx
# Linha 62: "Adicionar Tarefa" → "Add Tarefa: AmazonQ"
```

#### **Passo 2: Deploy da mudança**
```bash
./deploy-versioned.sh deploy
```
**Resultado:**
- ✅ Tag criada: `v20250731-224437`
- ✅ Imagem enviada para ECR
- ✅ Deploy realizado com sucesso
- ✅ Aplicação atualizada: http://44.203.21.88

#### **Passo 3: Se não gostar da mudança (Rollback)**
```bash
./deploy-versioned.sh rollback
```
**Resultado:**
- ✅ Volta para versão anterior automaticamente
- ✅ Botão volta a ser "Adicionar Tarefa"

#### **Passo 4: Rollback para versão específica (se necessário)**
```bash
# Listar versões disponíveis
./deploy-versioned.sh list

# Voltar para versão específica
./deploy-versioned.sh rollback v20250731-180000
```

## 🔧 **Arquivos de Controle**

### **`.last-deployed-image`**
- **Função:** Armazena a imagem da versão anterior
- **Localização:** `/home/ec2-user/bia/.last-deployed-image`
- **Uso:** Rollback automático
- **Exemplo:** `387678648422.dkr.ecr.us-east-1.amazonaws.com/bia:latest`

### **Arquivos temporários**
- `temp_task_def.json` - Task definition temporária
- `rollback_task_def.json` - Task definition para rollback
- **Limpeza:** Removidos automaticamente após uso

## 📊 **Versionamento no ECR**

### **Estrutura das Tags**
```
v20250731-224437  # Deploy atual (botão alterado)
v20250731-180000  # Deploy anterior
v20250731-120000  # Deploy mais antigo
latest            # Sempre aponta para última versão
```

### **Identificação das Imagens**
- **Tag versionada:** `v20250731-224437`
- **Hash SHA256:** `sha256:e05218101388583d57d3c6b6bac30f87e627696706c1840170904fef1e7eefd1`
- **Data/Hora:** `2025-07-31T22:44:51.192000+00:00`

## ⚠️ **Boas Práticas**

### **✅ Antes do Deploy**
- Testar mudanças localmente
- Verificar se não há erros de sintaxe
- Confirmar que a aplicação compila

### **✅ Após o Deploy**
- Verificar se aplicação está respondendo
- Testar funcionalidade alterada
- Manter backup da versão anterior

### **✅ Para Rollback**
- Usar rollback automático para voltar uma versão
- Usar rollback manual para versões específicas
- Sempre verificar status após rollback

## 🚨 **Troubleshooting**

### **Problema: Deploy falha**
```bash
# Verificar logs do build
docker logs <container-id>

# Verificar status do service
./deploy-versioned.sh status

# Fazer rollback se necessário
./deploy-versioned.sh rollback
```

### **Problema: Rollback não funciona**
```bash
# Verificar se arquivo de backup existe
ls -la .last-deployed-image

# Listar versões disponíveis
./deploy-versioned.sh list

# Rollback manual para versão conhecida
./deploy-versioned.sh rollback v20250731-180000
```

### **Problema: Aplicação não responde**
```bash
# Verificar health check
curl http://44.203.21.88/api/versao

# Verificar status ECS
aws ecs describe-services --cluster cluster-bia --services service-bia --region us-east-1

# Verificar logs
aws logs describe-log-groups --log-group-name-prefix /ecs/task-def-bia --region us-east-1
```

## 🎉 **Resultado Atual**

### **✅ Deploy Realizado com Sucesso**
- **Versão atual:** `v20250731-224437`
- **Mudança:** Botão alterado para "Add Tarefa: AmazonQ"
- **URL:** http://44.203.21.88
- **Status:** ✅ Funcionando
- **Rollback:** ✅ Disponível

### **📋 Próximos Passos**
1. **Testar a mudança** no navegador
2. **Se gostar:** Manter a versão atual
3. **Se não gostar:** `./deploy-versioned.sh rollback`
4. **Para outras mudanças:** Repetir o processo

---

## 🔗 **Integração com Projeto BIA**

Este sistema segue a **filosofia de simplicidade** do projeto BIA:
- ✅ Comandos simples e diretos
- ✅ Feedback visual colorido
- ✅ Processo automatizado
- ✅ Segurança com rollback
- ✅ Versionamento claro

**Criado em:** 31/07/2025 22:46 UTC  
**Primeira versão deployada:** v20250731-224437  
**Mudança:** Botão "Adicionar Tarefa" → "Add Tarefa: AmazonQ"
