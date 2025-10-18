# 🔧 Troubleshooting - Instâncias EC2

## 🚨 Problemas Comuns e Soluções

### 1. **Não consigo conectar via SSH**

#### Sintomas
- Timeout na conexão SSH
- "Connection refused" ou "Connection timed out"
- Chave rejeitada

#### Diagnóstico
```bash
# Verificar se a instância está rodando
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Verificar Security Groups
aws ec2 describe-security-groups --group-ids sg-12345678

# Testar conectividade
telnet <IP_PUBLICO> 22
```

#### Soluções
1. **Verificar Security Group**
   ```bash
   # Adicionar regra SSH se necessário
   aws ec2 authorize-security-group-ingress \
       --group-id sg-12345678 \
       --protocol tcp \
       --port 22 \
       --cidr 0.0.0.0/0
   ```

2. **Verificar Key Pair**
   ```bash
   # Verificar permissões do arquivo .pem
   chmod 400 meu-key-pair.pem
   
   # Testar conexão
   ssh -i meu-key-pair.pem -v ubuntu@<IP_PUBLICO>
   ```

3. **Verificar estado da instância**
   ```bash
   # Se a instância estiver parada, iniciar
   aws ec2 start-instances --instance-ids i-1234567890abcdef0
   ```

### 2. **Instância não responde**

#### Sintomas
- SSH não conecta
- Aplicação não responde
- Timeout em requisições

#### Diagnóstico
```bash
# Verificar status da instância
aws ec2 describe-instance-status --instance-ids i-1234567890abcdef0

# Verificar métricas do CloudWatch
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average
```

#### Soluções
1. **Reiniciar instância**
   ```bash
   aws ec2 reboot-instances --instance-ids i-1234567890abcdef0
   ```

2. **Verificar logs do sistema**
   ```bash
   # Via Systems Manager (se configurado)
   aws ssm start-session --target i-1234567890abcdef0
   
   # Ou via console AWS
   # EC2 > Instances > Actions > Monitor and troubleshoot > Get system log
   ```

3. **Verificar uso de recursos**
   ```bash
   # Conectar via Session Manager e verificar
   top
   df -h
   free -h
   ```

### 3. **Problemas de Performance**

#### Sintomas
- Aplicação lenta
- Alto uso de CPU
- Alto uso de memória

#### Diagnóstico
```bash
# Verificar métricas detalhadas
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average,Maximum

# Verificar métricas de rede
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name NetworkIn \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average,Maximum
```

#### Soluções
1. **Aumentar tipo de instância**
   ```bash
   # Parar instância
   aws ec2 stop-instances --instance-ids i-1234567890abcdef0
   
   # Aguardar parar completamente
   aws ec2 wait instance-stopped --instance-ids i-1234567890abcdef0
   
   # Modificar tipo
   aws ec2 modify-instance-attribute \
       --instance-id i-1234567890abcdef0 \
       --instance-type t3.medium
   
   # Iniciar instância
   aws ec2 start-instances --instance-ids i-1234567890abcdef0
   ```

2. **Otimizar aplicação**
   ```bash
   # Verificar processos
   ps aux --sort=-%cpu | head -10
   ps aux --sort=-%mem | head -10
   
   # Verificar uso de disco
   df -h
   du -sh /* | sort -hr
   ```

### 4. **Problemas de Storage**

#### Sintomas
- "No space left on device"
- Aplicação não consegue escrever arquivos
- Performance degradada

#### Diagnóstico
```bash
# Verificar uso de disco
df -h

# Verificar arquivos grandes
du -sh /* | sort -hr

# Verificar inodes
df -i
```

#### Soluções
1. **Limpar espaço**
   ```bash
   # Limpar logs antigos
   sudo journalctl --vacuum-time=7d
   
   # Limpar cache do apt
   sudo apt clean
   sudo apt autoremove
   
   # Limpar arquivos temporários
   sudo rm -rf /tmp/*
   ```

2. **Expandir volume EBS**
   ```bash
   # Expandir volume via AWS CLI
   aws ec2 modify-volume --volume-id vol-12345678 --size 20
   
   # Expandir filesystem (dentro da instância)
   sudo growpart /dev/xvda1 1
   sudo resize2fs /dev/xvda1
   ```

### 5. **Problemas de Rede**

#### Sintomas
- Não consegue acessar internet
- DNS não resolve
- Conectividade intermitente

#### Diagnóstico
```bash
# Testar conectividade
ping 8.8.8.8
ping google.com

# Verificar configuração de rede
ip route show
cat /etc/resolv.conf

# Verificar DNS
nslookup google.com
```

#### Soluções
1. **Verificar Route Tables**
   ```bash
   # Verificar rotas da VPC
   aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345678"
   ```

2. **Verificar Internet Gateway**
   ```bash
   # Verificar se IGW está anexado
   aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-12345678"
   ```

3. **Configurar DNS**
   ```bash
   # Editar /etc/resolv.conf
   sudo nano /etc/resolv.conf
   
   # Adicionar:
   nameserver 8.8.8.8
   nameserver 8.8.4.4
   ```

## 🔍 Comandos de Diagnóstico

### Verificação Geral do Sistema
```bash
# Status geral
uptime
who
w

# Uso de recursos
top
htop
free -h
df -h

# Processos
ps aux
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10

# Conexões de rede
netstat -tulpn
ss -tulpn
```

### Logs do Sistema
```bash
# Logs de sistema
sudo tail -f /var/log/syslog
sudo journalctl -f

# Logs de autenticação
sudo tail -f /var/log/auth.log

# Logs do kernel
sudo dmesg | tail -20

# Logs de aplicação (exemplo: Apache)
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log
```

### Verificação de Segurança
```bash
# Tentativas de login
sudo grep "Failed password" /var/log/auth.log | tail -10

# Conexões SSH ativas
sudo ss -tulpn | grep :22

# Processos suspeitos
ps aux | grep -E "(nc|netcat|nmap|masscan|python|perl)"

# Arquivos modificados recentemente
find / -type f -mtime -1 2>/dev/null | head -20
```

## 📊 Monitoramento Proativo

### Script de Monitoramento
```bash
#!/bin/bash
# monitor-health.sh

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)

echo "Instance: $INSTANCE_ID"
echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEMORY_USAGE%"
echo "Disk Usage: $DISK_USAGE%"

# Alertas
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "ALERT: High CPU usage!"
fi

if (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
    echo "ALERT: High memory usage!"
fi

if [ "$DISK_USAGE" -gt 80 ]; then
    echo "ALERT: High disk usage!"
fi
```

### CloudWatch Custom Metrics
```bash
# Instalar CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configurar métricas customizadas
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

## 🆘 Contatos e Recursos

### AWS Support
- **Basic Support**: Documentação e fóruns
- **Developer Support**: $29/mês - Suporte por email
- **Business Support**: $100/mês - Suporte 24/7
- **Enterprise Support**: $15,000/mês - Suporte dedicado

### Recursos Úteis
- [AWS EC2 Troubleshooting Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/troubleshooting.html)
- [AWS Support Center](https://console.aws.amazon.com/support/)
- [AWS Health Dashboard](https://status.aws.amazon.com/)
- [AWS Forums](https://forums.aws.amazon.com/)

### Logs Importantes
- `/var/log/syslog` - Logs gerais do sistema
- `/var/log/auth.log` - Logs de autenticação
- `/var/log/kern.log` - Logs do kernel
- `/var/log/cloud-init.log` - Logs de inicialização
- `/var/log/cloud-init-output.log` - Output da inicialização
