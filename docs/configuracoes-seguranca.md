# 🔒 Configurações de Segurança para Instâncias EC2

## 🛡️ Security Groups - Boas Práticas

### Regras Essenciais

#### SSH (Porta 22)
```json
{
  "Type": "SSH",
  "Protocol": "tcp",
  "Port": 22,
  "Source": "SEU_IP/32"  // Restringir ao seu IP
}
```

#### HTTP/HTTPS (Portas 80/443)
```json
{
  "Type": "HTTP",
  "Protocol": "tcp",
  "Port": 80,
  "Source": "0.0.0.0/0"
},
{
  "Type": "HTTPS", 
  "Protocol": "tcp",
  "Port": 443,
  "Source": "0.0.0.0/0"
}
```

### Configuração via AWS CLI
```bash
# Criar security group
aws ec2 create-security-group \
    --group-name web-server-sg \
    --description "Security group para servidor web"

# Adicionar regras
aws ec2 authorize-security-group-ingress \
    --group-name web-server-sg \
    --protocol tcp \
    --port 22 \
    --cidr SEU_IP/32

aws ec2 authorize-security-group-ingress \
    --group-name web-server-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
```

## 🔑 Key Pairs - Gerenciamento Seguro

### Criar Key Pair
```bash
# Gerar nova chave
aws ec2 create-key-pair \
    --key-name meu-key-pair \
    --query 'KeyMaterial' \
    --output text > meu-key-pair.pem

# Definir permissões corretas
chmod 400 meu-key-pair.pem
```

### Boas Práticas
- ✅ Nunca compartilhe arquivos .pem
- ✅ Use chaves diferentes para ambientes diferentes
- ✅ Rotacione chaves periodicamente
- ✅ Armazene chaves em local seguro
- ❌ Nunca commite chaves no Git

## 🌐 VPC e Networking

### Configuração de VPC
```bash
# Criar VPC
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MinhaVPC}]'

# Criar subnets
aws ec2 create-subnet \
    --vpc-id vpc-12345678 \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a

# Criar Internet Gateway
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=MinhaIGW}]'
```

### Network ACLs
```bash
# Criar Network ACL
aws ec2 create-network-acl \
    --vpc-id vpc-12345678 \
    --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=MinhaNACL}]'

# Adicionar regras
aws ec2 create-network-acl-entry \
    --network-acl-id acl-12345678 \
    --rule-number 100 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=22,To=22 \
    --cidr-block 0.0.0.0/0
```

## 👤 IAM Roles e Policies

### Criar Role para EC2
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Policy para acesso ao S3
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::meu-bucket/*"
    }
  ]
}
```

### Aplicar Role à instância
```bash
aws ec2 associate-iam-instance-profile \
    --instance-id i-1234567890abcdef0 \
    --iam-instance-profile Name=MinhaRole
```

## 🔐 Hardening do Sistema

### Configurações SSH
```bash
# /etc/ssh/sshd_config
Port 2222                    # Porta não padrão
PermitRootLogin no          # Desabilitar login root
PasswordAuthentication no   # Apenas chaves
PubkeyAuthentication yes    # Autenticação por chave
MaxAuthTries 3              # Limite de tentativas
ClientAliveInterval 300     # Timeout de conexão
```

### Firewall (UFW)
```bash
# Instalar UFW
sudo apt update && sudo apt install ufw

# Configurar regras
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Ativar firewall
sudo ufw enable
```

### Atualizações de Segurança
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar fail2ban
sudo apt install fail2ban

# Configurar fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 📊 Monitoramento de Segurança

### CloudTrail
```bash
# Criar trail
aws cloudtrail create-trail \
    --name meu-trail \
    --s3-bucket-name meu-bucket-logs

# Iniciar logging
aws cloudtrail start-logging \
    --name meu-trail
```

### CloudWatch Alarms
```bash
# Alarm para tentativas de login SSH
aws cloudwatch put-metric-alarm \
    --alarm-name "SSH-Login-Attempts" \
    --alarm-description "Monitora tentativas de login SSH" \
    --metric-name "SSH-Login-Attempts" \
    --namespace "AWS/EC2" \
    --statistic "Sum" \
    --period 300 \
    --threshold 10 \
    --comparison-operator "GreaterThanThreshold"
```

### GuardDuty
```bash
# Habilitar GuardDuty
aws guardduty create-detector \
    --enable \
    --finding-publishing-frequency FIFTEEN_MINUTES
```

## 🚨 Incident Response

### Checklist de Segurança
- [ ] Verificar logs de acesso
- [ ] Analisar métricas do CloudWatch
- [ ] Verificar integridade dos arquivos
- [ ] Validar configurações de segurança
- [ ] Atualizar patches de segurança
- [ ] Rotacionar credenciais se necessário

### Comandos de Investigação
```bash
# Verificar usuários ativos
who
w

# Verificar processos suspeitos
ps aux | grep -E "(nc|netcat|nmap|masscan)"

# Verificar conexões de rede
netstat -tulpn

# Verificar logs de autenticação
sudo tail -f /var/log/auth.log

# Verificar integridade de arquivos críticos
sudo debsums -c
```

## 📋 Checklist de Segurança

### Antes do Deploy
- [ ] Security Groups configurados corretamente
- [ ] Key Pairs criados e seguros
- [ ] VPC e subnets configurados
- [ ] IAM roles e policies definidos
- [ ] Backup strategy implementada

### Após o Deploy
- [ ] Firewall configurado
- [ ] SSH hardening aplicado
- [ ] Sistema atualizado
- [ ] Monitoramento ativo
- [ ] Logs centralizados
- [ ] Backup funcionando

### Manutenção Contínua
- [ ] Atualizações de segurança regulares
- [ ] Revisão de logs
- [ ] Teste de backup/restore
- [ ] Auditoria de permissões
- [ ] Rotação de credenciais
