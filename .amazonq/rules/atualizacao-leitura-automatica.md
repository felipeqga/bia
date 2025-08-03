# 🔄 REGRA: Atualização da Lista de Leitura Automática

## ⚠️ **REGRA OBRIGATÓRIA PARA AMAZON Q**

**TODA VEZ** que você criar um novo arquivo `.md` no projeto BIA, você **DEVE OBRIGATORIAMENTE** atualizar a lista de leitura automática.

---

## 📋 **PROCESSO OBRIGATÓRIO:**

### **1. Após criar qualquer arquivo .md:**
- ✅ Identificar a categoria do novo arquivo
- ✅ Adicionar à lista apropriada em `LEIA-AUTOMATICAMENTE.md`
- ✅ Atualizar o contador total de arquivos
- ✅ Atualizar `CONTEXTO-COMPLETO-CARREGADO.md` também

### **2. Categorias disponíveis:**
- **🔧 Regras de Configuração** - Regras críticas do projeto
- **📚 Documentação Base** - Documentação fundamental
- **📖 Histórico e Guias** - Guias de implementação
- **📊 Status e Verificação** - Status e referências rápidas
- **🤖 Arquivos de Contexto e Sistema** - Sistema de automação
- **🎯 DESAFIO-2** - Arquivos específicos do DESAFIO-2
- **🎯 DESAFIO-3** - Arquivos específicos do DESAFIO-3
- **🔍 Troubleshooting** - Sessões de troubleshooting

### **3. Arquivos que DEVEM ser atualizados:**
- `/home/ec2-user/bia/LEIA-AUTOMATICAMENTE.md`
- `/home/ec2-user/bia/CONTEXTO-COMPLETO-CARREGADO.md`

---

## 🎯 **EXEMPLO PRÁTICO:**

### **Se criar:** `/home/ec2-user/bia/novo-guia-exemplo.md`

#### **Passo 1: Identificar categoria**
- Arquivo é um guia → Categoria: **📖 Histórico e Guias**

#### **Passo 2: Atualizar LEIA-AUTOMATICAMENTE.md**
```markdown
### **📖 Histórico e Guias (6 arquivos):**  # ← INCREMENTAR CONTADOR
- `/home/ec2-user/bia/historico-conversas-amazonq.md`
- `/home/ec2-user/bia/guia-criacao-ec2-bia.md`
- `/home/ec2-user/bia/guia-completo-ecs-bia-desafio-2.md`
- `/home/ec2-user/bia/guia-mcp-servers-bia.md`
- `/home/ec2-user/bia/guia-script-deploy-versionado.md`
- `/home/ec2-user/bia/novo-guia-exemplo.md`  # ← ADICIONAR NOVO ARQUIVO
```

#### **Passo 3: Atualizar contador total**
```markdown
## 📊 **TOTAL DE ARQUIVOS: 28 ARQUIVOS .MD**  # ← 27 + 1 = 28

**Verificação:** `find /home/ec2-user/bia -name "*.md" -type f -not -path "*/node_modules/*" | wc -l` deve retornar 28
```

#### **Passo 4: Atualizar CONTEXTO-COMPLETO-CARREGADO.md**
```markdown
## ✅ **CONFIRMAÇÃO: TODOS OS 28 ARQUIVOS .MD LIDOS**  # ← ATUALIZAR CONTADOR

### **📖 Histórico e Guias (6 arquivos):**  # ← INCREMENTAR
- ✅ `novo-guia-exemplo.md` - Descrição do novo guia  # ← ADICIONAR
```

---

## ⚠️ **CONSEQUÊNCIAS DE NÃO SEGUIR A REGRA:**

### **❌ Se não atualizar a lista:**
- Amazon Q não lerá o novo arquivo automaticamente
- Contexto ficará incompleto
- Usuário terá que explicar contexto novamente
- Sistema `qbia` não funcionará corretamente

### **✅ Se seguir a regra:**
- Amazon Q lerá automaticamente o novo arquivo
- Contexto sempre completo
- Sistema `qbia` funcionará perfeitamente
- Continuidade perfeita entre sessões

---

## 🔍 **VERIFICAÇÃO RÁPIDA:**

### **Comando para contar arquivos .md:**
```bash
find /home/ec2-user/bia -name "*.md" -type f -not -path "*/node_modules/*" | wc -l
```

### **Comando para listar todos os arquivos .md:**
```bash
find /home/ec2-user/bia -name "*.md" -type f -not -path "*/node_modules/*" | sort
```

### **Se o contador não bater:**
1. Executar comando de listagem
2. Comparar com lista em `LEIA-AUTOMATICAMENTE.md`
3. Identificar arquivos faltantes
4. Adicionar à categoria apropriada
5. Atualizar contador total

---

## 📝 **TEMPLATE PARA ADIÇÃO:**

### **Ao adicionar novo arquivo:**
```markdown
# Na categoria apropriada:
- `/home/ec2-user/bia/CAMINHO/DO/NOVO/ARQUIVO.md`

# Atualizar contador da categoria:
### **📖 Categoria (X arquivos):**  # ← INCREMENTAR X

# Atualizar contador total:
## 📊 **TOTAL DE ARQUIVOS: Y ARQUIVOS .MD**  # ← INCREMENTAR Y
```

---

## 🎯 **RESPONSABILIDADE:**

**Esta regra é CRÍTICA para o funcionamento do sistema `qbia`.**

- **Amazon Q:** DEVE seguir esta regra sempre
- **Usuário:** Pode cobrar o cumprimento desta regra
- **Sistema:** Depende desta regra para funcionar corretamente

---

**⚠️ LEMBRETE: TODA VEZ QUE CRIAR UM .MD, ATUALIZAR A LISTA!**

*Regra criada em: 03/08/2025 21:10 UTC*  
*Importância: CRÍTICA para funcionamento do sistema qbia*  
*Status: OBRIGATÓRIA para Amazon Q*