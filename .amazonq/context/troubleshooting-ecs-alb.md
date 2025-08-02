# Troubleshooting Guide - ECS com ALB

## 🚨 PROBLEMAS COMUNS E SOLUÇÕES

### ❌ **PROBLEMA: API retorna HTML em vez de JSON**

**Sintomas:**
```bash
curl http://alb-url/api/versao
# Resultado: "Bia 4.2.0" ✅

curl http://alb-url/api/usuarios  
# Resultado: HTML do React ❌
```

**Diagnóstico:**
- Endpoints que não precisam do banco funcionam
- Endpoints que precisam do banco retornam HTML
- Indica problema de conectividade com RDS

**Soluções:**
1. **Verificar variáveis de ambiente RDS:**
   ```json
   // IMPORTANTE: SEMPRE PERGUNTAR as variáveis atuais!
   // Valores mudam quando RDS é recriado:
   "environment": [
     {"name": "DB_HOST", "value": "PERGUNTAR_AO_USUARIO"},
     {"name": "DB_PORT", "value": "PERGUNTAR_AO_USUARIO"},
     {"name": "DB_USER", "value": "PERGUNTAR_AO_USUARIO"},
     {"name": "DB_PWD", "value": "PERGUNTAR_AO_USUARIO"}  // ← Verificar senha!
   ]
   ```

2. **Verificar Security Group bia-db:**
   ```bash
   aws ec2 describe-security-groups --group-names bia-db
   # Deve permitir porta 5432 do bia-ec2
   ```

3. **Verificar logs da aplicação:**
   ```bash
   aws logs get-log-events --log-group-name /ecs/task-def-bia-alb --log-stream-name xxx
   ```

---

### ❌ **PROBLEMA: Target Group Unhealthy**

**Sintomas:**
- ALB não responde ou retorna 503
- Target Group mostra targets unhealthy

**Diagnóstico:**
```bash
aws elbv2 describe-target-health --target-group-arn xxx
```

**Soluções:**
1. **Verificar AZs do ALB vs Instâncias:**
   ```bash
   # Verificar AZs do ALB
   aws elbv2 describe-load-balancers --names bia
   
   # Verificar AZs das instâncias
   aws ec2 describe-instances --filters "Name=tag:Project,Values=BIA"
   ```

2. **Verificar Security Groups:**
   ```bash
   # bia-alb deve permitir HTTP/HTTPS público
   # bia-ec2 deve permitir ALL TCP do bia-alb
   ```

3. **Verificar Health Check:**
   ```bash
   # Target Group deve usar /api/versao como health check
   aws elbv2 describe-target-groups --names tg-bia
   ```

---

### ❌ **PROBLEMA: Não consegue acessar instâncias EC2**

**Sintomas:**
- SSH não funciona
- Não consegue fazer troubleshooting

**Solução:**
1. **Verificar IAM Role:**
   ```bash
   aws ec2 describe-instances --instance-ids i-xxx
   # IamInstanceProfile deve ser "role-acesso-ssm"
   ```

2. **Usar SSM Session Manager:**
   ```bash
   aws ssm start-session --target i-xxx
   ```

---

### ❌ **PROBLEMA: Tasks não iniciam no ECS**

**Sintomas:**
- Service mostra 0 running tasks
- Tasks falham ao iniciar

**Diagnóstico:**
```bash
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb
aws ecs list-tasks --cluster cluster-bia-alb --service-name service-bia-alb
```

**Soluções:**
1. **Verificar se instâncias se registraram no cluster:**
   ```bash
   aws ecs list-container-instances --cluster cluster-bia-alb
   ```

2. **Verificar logs das tasks:**
   ```bash
   aws ecs describe-tasks --cluster cluster-bia-alb --tasks xxx
   ```

3. **Verificar recursos disponíveis:**
   - CPU e memória suficientes nas instâncias
   - Portas disponíveis para mapeamento aleatório

---

## 🔧 COMANDOS DE DIAGNÓSTICO

### **Status Geral:**
```bash
# ALB Status
aws elbv2 describe-load-balancers --names bia

# Target Group Health
aws elbv2 describe-target-health --target-group-arn xxx

# ECS Service Status
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb

# Container Instances
aws ecs list-container-instances --cluster cluster-bia-alb
```

### **Testes de Conectividade:**
```bash
# Health Check
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/api/versao

# Teste de Banco
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/api/usuarios

# Frontend
curl http://bia-1433396588.us-east-1.elb.amazonaws.com/
```

### **Logs:**
```bash
# Listar Log Streams
aws logs describe-log-streams --log-group-name /ecs/task-def-bia-alb

# Ver Logs
aws logs get-log-events --log-group-name /ecs/task-def-bia-alb --log-stream-name xxx
```

---

## 🎯 CHECKLIST DE VALIDAÇÃO

### **Antes de Reportar Problema:**
- [ ] ALB está em AZs corretas?
- [ ] Instâncias EC2 estão nas mesmas AZs do ALB?
- [ ] Security Groups estão configurados corretamente?
- [ ] Variáveis de ambiente RDS estão corretas?
- [ ] IAM Role das instâncias é role-acesso-ssm?
- [ ] Tasks estão rodando no ECS?
- [ ] Target Group está healthy?
- [ ] Health check está funcionando?

### **Testes Básicos:**
- [ ] `/api/versao` retorna "Bia 4.2.0"?
- [ ] `/api/usuarios` retorna JSON (não HTML)?
- [ ] Frontend carrega corretamente?
- [ ] Consegue acessar instâncias via SSM?

---

**Use este guia para resolver 90% dos problemas com ECS + ALB! 🎯**