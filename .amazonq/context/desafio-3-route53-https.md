# 🌐 DESAFIO-3: Route 53 + HTTPS - Contexto Técnico

## 📋 **CONFIGURAÇÃO COMPLETA PARA PRODUÇÃO**

**Data:** 04/08/2025  
**Status:** 📋 DOCUMENTADO (Requer domínio próprio)  
**Método:** Route 53 + ACM + ALB HTTPS  

---

## 🎯 **IMPORTANTE: PERGUNTA OBRIGATÓRIA**

**⚠️ SEMPRE perguntar ao usuário:**
- **"Qual domínio você possui?"** (ex: seudominio.com.br)
- **"Você tem acesso ao painel do Registro.br?"**
- **"Quer configurar HTTPS ou apenas HTTP?"**

**Exemplo genérico usado na documentação:** `eletroboards.com.br`  
**Deve ser substituído pelo domínio real do usuário!**

---

## 🌐 **PASSO 8: ROUTE 53 + ACM**

### **8.1 - Criar Hosted Zone:**

```bash
# ⚠️ SUBSTITUIR pelo domínio do usuário
DOMAIN="seudominio.com.br"

# Criar Hosted Zone
aws route53 create-hosted-zone \
  --name $DOMAIN \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Hosted Zone para projeto BIA - DESAFIO-3"
```

**📋 Resultado esperado:**
- 4 servidores DNS (ex: ns-123.awsdns-12.com)
- Anotar para configurar no Registro.br

### **8.2 - Configuração no Registro.br:**

**Instruções para o usuário:**
1. Acessar **registro.br**
2. Fazer login com CPF/CNPJ
3. Ir em **Meus Domínios** → **DNS**
4. Substituir os 4 DNS pelos do Route 53
5. Salvar e aguardar propagação (até 48h)

### **8.3 - Solicitar Certificados SSL:**

```bash
# Certificado Wildcard (*.seudominio.com.br)
aws acm request-certificate \
  --domain-name "*.${DOMAIN}" \
  --subject-alternative-names "${DOMAIN}" \
  --validation-method DNS \
  --key-algorithm RSA_2048

# Certificado específico (desafio3.seudominio.com.br)
aws acm request-certificate \
  --domain-name "desafio3.${DOMAIN}" \
  --validation-method DNS \
  --key-algorithm RSA_2048
```

### **8.4 - Validação DNS dos Certificados:**

```bash
# Listar certificados pendentes
aws acm list-certificates --certificate-statuses PENDING_VALIDATION

# Para cada certificado, obter registros de validação
aws acm describe-certificate --certificate-arn <CERT-ARN> \
  --query 'Certificate.DomainValidationOptions[*].ResourceRecord'

# Criar registros CNAME no Route 53 para validação
# (Processo automático via Console ou manual via CLI)
```

### **8.5 - Criar Record CNAME para Aplicação (⚠️ CRÍTICO):**

**🎯 PASSO OBRIGATÓRIO IDENTIFICADO PELO USUÁRIO:**
*"Temos que editar lá em hosted zones o CNAME desafio3.eletroboards.com.br o 'Value' com o DNS name do ALB"*

**📋 CONFIGURAÇÃO MANUAL (Console AWS) - RECOMENDADO:**
1. **Route 53** → **Hosted Zones** → **eletroboards.com.br**
2. **Create Record**
3. **Record Name:** `desafio3`
4. **Record Type:** `CNAME`
5. **Value:** `bia-1751550233.us-east-1.elb.amazonaws.com` (DNS do ALB)
6. **TTL:** 300
7. **Create Record**

**🎯 RESULTADO:** `desafio3.eletroboards.com.br` → ALB DNS

**💻 CONFIGURAÇÃO VIA CLI:**
```bash
# Obter Hosted Zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='${DOMAIN}.'].Id" --output text)

# Obter DNS do ALB
ALB_DNS=$(aws elbv2 describe-load-balancers --names bia \
  --query 'LoadBalancers[0].DNSName' --output text)

# Criar registro CNAME
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"CREATE\",
      \"ResourceRecordSet\": {
        \"Name\": \"desafio3.${DOMAIN}\",
        \"Type\": \"CNAME\",
        \"TTL\": 300,
        \"ResourceRecords\": [{\"Value\": \"${ALB_DNS}\"}]
      }
    }]
  }"
```

**✅ STATUS ATUAL:** CNAME já criado e funcionando corretamente!

---

## 🔐 **PASSO 9: LISTENER HTTPS**

### **9.1 - Obter ARN do Certificado:**

```bash
# Listar certificados emitidos
aws acm list-certificates --certificate-statuses ISSUED

# Obter ARN específico
CERT_ARN=$(aws acm list-certificates \
  --query "CertificateSummaryList[?DomainName=='desafio3.${DOMAIN}'].CertificateArn" \
  --output text)
```

### **9.2 - Criar Listener HTTPS:**

```bash
# Obter ARN do ALB
ALB_ARN=$(aws elbv2 describe-load-balancers --names bia \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Obter ARN do Target Group
TG_ARN=$(aws elbv2 describe-target-groups --names tg-bia \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Criar Listener HTTPS
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

### **9.3 - Atualizar Security Group:**

```bash
# Obter ID do Security Group do ALB
ALB_SG_ID=$(aws elbv2 describe-load-balancers --names bia \
  --query 'LoadBalancers[0].SecurityGroups[0]' --output text)

# Adicionar regra HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

### **9.4 - Atualizar Dockerfile:**

```dockerfile
# Atualizar VITE_API_URL para HTTPS
RUN cd client && VITE_API_URL=https://desafio3.seudominio.com.br npm run build
```

### **9.5 - Configurar Redirect HTTP → HTTPS:**

```bash
# Obter ARN do Listener HTTP
HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN \
  --query 'Listeners[?Port==`80`].ListenerArn' --output text)

# Configurar redirect
aws elbv2 modify-listener \
  --listener-arn $HTTP_LISTENER_ARN \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,StatusCode=HTTP_301,Port=443}'
```

---

## 📊 **CONFIGURAÇÕES FINAIS:**

### **🎯 Configuração Mínima (Educacional):**
- **1 Listener HTTP (80):** Forward → tg-bia
- **DNS:** ALB DNS direto
- **Certificado:** Não necessário

### **🔐 Configuração Completa (Produção):**
- **2 Listeners:** HTTP (80) + HTTPS (443)
- **DNS:** Route 53 + domínio personalizado
- **Certificado:** ACM com validação DNS
- **Redirect:** HTTP → HTTPS

---

## 🧪 **TESTES DE VALIDAÇÃO:**

### **Verificar DNS:**
```bash
# Testar resolução DNS
nslookup desafio3.seudominio.com.br

# Verificar propagação
dig desafio3.seudominio.com.br CNAME
```

### **Testar Aplicação:**
```bash
# HTTP (deve redirecionar)
curl -I http://desafio3.seudominio.com.br/api/versao

# HTTPS
curl https://desafio3.seudominio.com.br/api/versao

# Verificar certificado
openssl s_client -connect desafio3.seudominio.com.br:443 \
  -servername desafio3.seudominio.com.br
```

---

## 📋 **CHECKLIST COMPLETO:**

### **✅ Pré-requisitos:**
- [ ] Domínio registrado no Registro.br
- [ ] Acesso ao painel do Registro.br
- [ ] Permissões AWS: Route53, ACM, ELB

### **✅ Route 53:**
- [ ] Hosted Zone criada
- [ ] 4 DNS anotados
- [ ] DNS configurados no Registro.br
- [ ] Propagação confirmada (48h)

### **✅ ACM:**
- [ ] Certificado solicitado
- [ ] Registros de validação criados
- [ ] Certificado emitido (Status: ISSUED)

### **✅ ALB:**
- [ ] Listener HTTPS criado
- [ ] Certificado SSL associado
- [ ] Security Group atualizado (porta 443)
- [ ] Redirect HTTP → HTTPS configurado

### **✅ Aplicação:**
- [ ] Dockerfile atualizado com HTTPS
- [ ] Nova imagem buildada
- [ ] Deploy realizado
- [ ] Testes HTTP e HTTPS funcionando

---

## 💰 **CUSTOS ESTIMADOS:**

| **Recurso** | **Custo Mensal** | **Observações** |
|-------------|------------------|-----------------|
| **Route 53 Hosted Zone** | $0.50 | Por zona hospedada |
| **Route 53 Queries** | $0.40/milhão | Consultas DNS |
| **ACM Certificate** | $0.00 | Gratuito para uso com ALB |
| **ALB** | ~$16.00 | Já contabilizado |

**Total adicional:** ~$1.00/mês

---

## 🎯 **RESUMO:**

**Esta configuração é para PRODUÇÃO com:**
- ✅ **Domínio personalizado**
- ✅ **DNS gerenciado pelo Route 53**
- ✅ **Certificado SSL válido e gratuito**
- ✅ **HTTPS obrigatório**
- ✅ **SEO e segurança otimizados**

**Para fins educacionais, HTTP é suficiente!**

---

*Última atualização: 04/08/2025 01:30 UTC*  
*Status: DOCUMENTADO para implementação com domínio próprio*  
*Exemplo genérico: eletroboards.com.br (substituir pelo domínio real)*