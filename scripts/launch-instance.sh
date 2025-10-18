#!/bin/bash

# 🚀 Script para Lançar Instância EC2
# Autor: [Seu Nome]
# Data: $(date +%Y-%m-%d)
# Versão: 1.0.0

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configurações padrão
DEFAULT_AMI="ami-0c02fb55956c7d316"  # Ubuntu 22.04 LTS
DEFAULT_INSTANCE_TYPE="t2.micro"
DEFAULT_KEY_NAME=""
DEFAULT_SECURITY_GROUP=""
DEFAULT_REGION="us-east-1"

# Função para mostrar ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES]

Script para lançar instâncias EC2 na AWS

OPÇÕES:
    -a, --ami AMI_ID              ID da AMI (padrão: $DEFAULT_AMI)
    -t, --type INSTANCE_TYPE      Tipo da instância (padrão: $DEFAULT_INSTANCE_TYPE)
    -k, --key KEY_NAME            Nome do key pair
    -s, --sg SECURITY_GROUP       Nome do security group
    -r, --region REGION           Região AWS (padrão: $DEFAULT_REGION)
    -n, --name INSTANCE_NAME      Nome da instância
    -c, --count COUNT             Número de instâncias (padrão: 1)
    -h, --help                    Mostrar esta ajuda

EXEMPLOS:
    $0 -k meu-key-pair -s web-sg -n "Web Server"
    $0 --ami ami-12345678 --type t3.small --key meu-key --sg web-sg --name "App Server"
    $0 -k meu-key -s web-sg -n "Load Balancer" -c 2

REQUISITOS:
    - AWS CLI configurado
    - Permissões para criar instâncias EC2
    - Key pair e security group já existentes

EOF
}

# Função para validar dependências
validate_dependencies() {
    log "Validando dependências..."
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI não configurado ou credenciais inválidas"
        exit 1
    fi
    
    success "Dependências validadas"
}

# Função para validar parâmetros
validate_parameters() {
    log "Validando parâmetros..."
    
    if [[ -z "$KEY_NAME" ]]; then
        error "Key pair é obrigatório (-k ou --key)"
        exit 1
    fi
    
    if [[ -z "$SECURITY_GROUP" ]]; then
        error "Security group é obrigatório (-s ou --sg)"
        exit 1
    fi
    
    if [[ -z "$INSTANCE_NAME" ]]; then
        error "Nome da instância é obrigatório (-n ou --name)"
        exit 1
    fi
    
    success "Parâmetros validados"
}

# Função para verificar se key pair existe
check_key_pair() {
    log "Verificando key pair: $KEY_NAME"
    
    if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &> /dev/null; then
        error "Key pair '$KEY_NAME' não encontrado na região $REGION"
        exit 1
    fi
    
    success "Key pair encontrado"
}

# Função para verificar se security group existe
check_security_group() {
    log "Verificando security group: $SECURITY_GROUP"
    
    if ! aws ec2 describe-security-groups --group-names "$SECURITY_GROUP" --region "$REGION" &> /dev/null; then
        error "Security group '$SECURITY_GROUP' não encontrado na região $REGION"
        exit 1
    fi
    
    success "Security group encontrado"
}

# Função para lançar instância
launch_instance() {
    log "Lançando $COUNT instância(s)..."
    
    local launch_result
    launch_result=$(aws ec2 run-instances \
        --image-id "$AMI" \
        --count "$COUNT" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-groups "$SECURITY_GROUP" \
        --region "$REGION" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Environment,Value=Development},{Key=CreatedBy,Value=Script},{Key=CreatedDate,Value=$(date +%Y-%m-%d)}]" \
        --output json)
    
    if [[ $? -eq 0 ]]; then
        success "Instância(s) lançada(s) com sucesso!"
        
        # Extrair IDs das instâncias
        local instance_ids
        instance_ids=$(echo "$launch_result" | jq -r '.Instances[].InstanceId')
        
        echo "$instance_ids" | while read -r instance_id; do
            log "ID da instância: $instance_id"
        done
        
        # Aguardar instância ficar running
        log "Aguardando instância(s) ficar(em) em estado 'running'..."
        aws ec2 wait instance-running --instance-ids $instance_ids --region "$REGION"
        
        # Obter IP público
        log "Obtendo informações das instâncias..."
        aws ec2 describe-instances \
            --instance-ids $instance_ids \
            --region "$REGION" \
            --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' \
            --output table
        
        success "Instância(s) pronta(s) para uso!"
        
    else
        error "Falha ao lançar instância(s)"
        exit 1
    fi
}

# Função para mostrar informações pós-criação
show_post_creation_info() {
    log "Informações pós-criação:"
    
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Aguarde alguns minutos para a instância inicializar completamente"
    echo "2. Conecte via SSH: ssh -i $KEY_NAME.pem ubuntu@<IP_PUBLICO>"
    echo "3. Configure sua aplicação"
    echo "4. Configure monitoramento se necessário"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "- Ver status: aws ec2 describe-instances --instance-ids <INSTANCE_ID>"
    echo "- Parar: aws ec2 stop-instances --instance-ids <INSTANCE_ID>"
    echo "- Iniciar: aws ec2 start-instances --instance-ids <INSTANCE_ID>"
    echo "- Terminar: aws ec2 terminate-instances --instance-ids <INSTANCE_ID>"
    echo ""
}

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--ami)
            AMI="$2"
            shift 2
            ;;
        -t|--type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -k|--key)
            KEY_NAME="$2"
            shift 2
            ;;
        -s|--sg)
            SECURITY_GROUP="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -n|--name)
            INSTANCE_NAME="$2"
            shift 2
            ;;
        -c|--count)
            COUNT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Definir valores padrão
AMI=${AMI:-$DEFAULT_AMI}
INSTANCE_TYPE=${INSTANCE_TYPE:-$DEFAULT_INSTANCE_TYPE}
REGION=${REGION:-$DEFAULT_REGION}
COUNT=${COUNT:-1}

# Função principal
main() {
    log "Iniciando script de lançamento de instância EC2..."
    
    validate_dependencies
    validate_parameters
    check_key_pair
    check_security_group
    launch_instance
    show_post_creation_info
    
    success "Script concluído com sucesso!"
}

# Executar função principal
main "$@"
