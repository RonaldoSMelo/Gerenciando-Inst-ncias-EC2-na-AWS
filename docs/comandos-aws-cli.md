# 🖥️ Comandos AWS CLI - Gerenciamento de Instâncias EC2

## 📋 Configuração Inicial

### Configurar credenciais AWS
```bash
aws configure
```

### Verificar configuração
```bash
aws sts get-caller-identity
```

## 🚀 Criação de Instâncias

### Listar AMIs disponíveis
```bash
# Ubuntu 22.04 LTS
aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query 'Images[*].[ImageId,Name,CreationDate]' --output table

# Amazon Linux 2
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*" --query 'Images[*].[ImageId,Name,CreationDate]' --output table
```

### Criar Key Pair
```bash
aws ec2 create-key-pair --key-name meu-key-pair --query 'KeyMaterial' --output text > meu-key-pair.pem
chmod 400 meu-key-pair.pem
```

### Criar Security Group
```bash
# Criar security group
aws ec2 create-security-group --group-name meu-sg --description "Security group para instâncias EC2"

# Adicionar regra SSH (porta 22)
aws ec2 authorize-security-group-ingress --group-name meu-sg --protocol tcp --port 22 --cidr 0.0.0.0/0

# Adicionar regra HTTP (porta 80)
aws ec2 authorize-security-group-ingress --group-name meu-sg --protocol tcp --port 80 --cidr 0.0.0.0/0

# Adicionar regra HTTPS (porta 443)
aws ec2 authorize-security-group-ingress --group-name meu-sg --protocol tcp --port 443 --cidr 0.0.0.0/0
```

### Lançar instância
```bash
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t2.micro \
    --key-name meu-key-pair \
    --security-groups meu-sg \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MinhaInstancia},{Key=Environment,Value=Development}]'
```

## 📊 Monitoramento e Gerenciamento

### Listar instâncias
```bash
# Todas as instâncias
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table

# Instâncias em execução
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Conectar via SSH
```bash
ssh -i meu-key-pair.pem ubuntu@<IP_PUBLICO>
```

### Parar/Iniciar instâncias
```bash
# Parar instância
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Iniciar instância
aws ec2 start-instances --instance-ids i-1234567890abcdef0

# Reiniciar instância
aws ec2 reboot-instances --instance-ids i-1234567890abcdef0
```

### Terminar instância
```bash
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

## 💾 Backup e Snapshots

### Criar snapshot de volume
```bash
aws ec2 create-snapshot --volume-id vol-1234567890abcdef0 --description "Backup do volume principal"
```

### Listar snapshots
```bash
aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[*].[SnapshotId,VolumeId,State,StartTime,Description]' --output table
```

### Criar AMI a partir de instância
```bash
aws ec2 create-image --instance-id i-1234567890abcdef0 --name "Minha-AMI-$(date +%Y%m%d)" --description "AMI criada a partir da instância"
```

## 🔧 Configurações Avançadas

### Modificar tipo de instância
```bash
aws ec2 modify-instance-attribute --instance-id i-1234567890abcdef0 --instance-type t3.small
```

### Adicionar tags
```bash
aws ec2 create-tags --resources i-1234567890abcdef0 --tags Key=Backup,Value=Daily Key=Owner,Value=DevTeam
```

### Configurar monitoramento detalhado
```bash
aws ec2 monitor-instances --instance-ids i-1234567890abcdef0
```

## 📈 CloudWatch

### Listar métricas
```bash
aws cloudwatch list-metrics --namespace AWS/EC2
```

### Obter estatísticas
```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-02T00:00:00Z \
    --period 3600 \
    --statistics Average
```

## 🚨 Troubleshooting

### Verificar logs do sistema
```bash
# Conectar na instância e verificar logs
sudo tail -f /var/log/syslog
sudo journalctl -f
```

### Verificar status dos serviços
```bash
sudo systemctl status apache2
sudo systemctl status nginx
```

### Verificar uso de disco
```bash
df -h
du -sh /*
```

## 📝 Scripts Úteis

### Script para backup automático
```bash
#!/bin/bash
# backup-ec2.sh

INSTANCE_ID="i-1234567890abcdef0"
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"

echo "Criando backup da instância $INSTANCE_ID..."
aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "$BACKUP_NAME" \
    --description "Backup automático criado em $(date)"

echo "Backup $BACKUP_NAME criado com sucesso!"
```

### Script para monitoramento
```bash
#!/bin/bash
# monitor-ec2.sh

aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```
