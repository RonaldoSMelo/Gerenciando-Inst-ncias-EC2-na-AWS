#!/bin/bash

# 💾 Script de Backup Automático para Instâncias EC2
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

# Configurações
BACKUP_RETENTION_DAYS=30
S3_BUCKET=""
REGION="us-east-1"
LOG_FILE="/var/log/ec2-backup.log"

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES]

Script para backup automático de instâncias EC2

OPÇÕES:
    -i, --instance-id INSTANCE_ID    ID da instância (obrigatório)
    -b, --bucket S3_BUCKET          Bucket S3 para backup (opcional)
    -r, --region REGION             Região AWS (padrão: us-east-1)
    -d, --retention-days DAYS       Dias de retenção (padrão: 30)
    -n, --name BACKUP_NAME          Nome personalizado do backup
    -t, --type BACKUP_TYPE          Tipo: snapshot, ami, both (padrão: both)
    -h, --help                      Mostrar esta ajuda

EXEMPLOS:
    $0 -i i-1234567890abcdef0
    $0 -i i-1234567890abcdef0 -b meu-bucket-backup -d 7
    $0 -i i-1234567890abcdef0 -n "Backup-Producao" -t ami
    $0 -i i-1234567890abcdef0 -t snapshot -d 14

REQUISITOS:
    - AWS CLI configurado
    - Permissões para criar snapshots e AMIs
    - Instância EC2 válida

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

# Função para validar instância
validate_instance() {
    log "Validando instância: $INSTANCE_ID"
    
    local instance_info
    instance_info=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0]' \
        --output json 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ "$instance_info" == "null" ]]; then
        error "Instância '$INSTANCE_ID' não encontrada na região $REGION"
        exit 1
    fi
    
    local instance_state
    instance_state=$(echo "$instance_info" | jq -r '.State.Name')
    
    if [[ "$instance_state" != "running" ]] && [[ "$instance_state" != "stopped" ]]; then
        error "Instância não está em estado válido para backup (Estado atual: $instance_state)"
        exit 1
    fi
    
    success "Instância validada (Estado: $instance_state)"
}

# Função para criar snapshot
create_snapshot() {
    log "Criando snapshot da instância..."
    
    local volumes
    volumes=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].BlockDeviceMappings[?Ebs.VolumeId!=`null`].Ebs.VolumeId' \
        --output text)
    
    local snapshot_ids=()
    
    for volume_id in $volumes; do
        log "Criando snapshot do volume: $volume_id"
        
        local snapshot_result
        snapshot_result=$(aws ec2 create-snapshot \
            --volume-id "$volume_id" \
            --description "Backup automático - $BACKUP_NAME - $(date +%Y-%m-%d)" \
            --region "$REGION" \
            --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$BACKUP_NAME},{Key=InstanceId,Value=$INSTANCE_ID},{Key=BackupDate,Value=$(date +%Y-%m-%d)},{Key=BackupType,Value=Automated}]" \
            --output json)
        
        if [[ $? -eq 0 ]]; then
            local snapshot_id
            snapshot_id=$(echo "$snapshot_result" | jq -r '.SnapshotId')
            snapshot_ids+=("$snapshot_id")
            success "Snapshot criado: $snapshot_id"
        else
            error "Falha ao criar snapshot do volume $volume_id"
        fi
    done
    
    if [[ ${#snapshot_ids[@]} -gt 0 ]]; then
        success "Snapshots criados: ${snapshot_ids[*]}"
    else
        error "Nenhum snapshot foi criado"
        exit 1
    fi
}

# Função para criar AMI
create_ami() {
    log "Criando AMI da instância..."
    
    local ami_result
    ami_result=$(aws ec2 create-image \
        --instance-id "$INSTANCE_ID" \
        --name "$BACKUP_NAME-$(date +%Y%m%d-%H%M%S)" \
        --description "Backup automático - $BACKUP_NAME - $(date +%Y-%m-%d)" \
        --no-reboot \
        --region "$REGION" \
        --output json)
    
    if [[ $? -eq 0 ]]; then
        local ami_id
        ami_id=$(echo "$ami_result" | jq -r '.ImageId')
        
        # Adicionar tags à AMI
        aws ec2 create-tags \
            --resources "$ami_id" \
            --tags Key=Name,Value="$BACKUP_NAME" Key=InstanceId,Value="$INSTANCE_ID" Key=BackupDate,Value="$(date +%Y-%m-%d)" Key=BackupType,Value=Automated \
            --region "$REGION"
        
        success "AMI criada: $ami_id"
    else
        error "Falha ao criar AMI"
        exit 1
    fi
}

# Função para limpar backups antigos
cleanup_old_backups() {
    log "Limpando backups antigos (mais de $BACKUP_RETENTION_DAYS dias)..."
    
    local cutoff_date
    cutoff_date=$(date -d "$BACKUP_RETENTION_DAYS days ago" +%Y-%m-%d)
    
    # Limpar AMIs antigas
    log "Limpando AMIs antigas..."
    local old_amis
    old_amis=$(aws ec2 describe-images \
        --owners self \
        --filters "Name=tag:BackupType,Values=Automated" "Name=tag:InstanceId,Values=$INSTANCE_ID" \
        --query "Images[?CreationDate<'$cutoff_date'].ImageId" \
        --output text \
        --region "$REGION")
    
    for ami_id in $old_amis; do
        if [[ -n "$ami_id" ]]; then
            log "Removendo AMI antiga: $ami_id"
            aws ec2 deregister-image --image-id "$ami_id" --region "$REGION"
            success "AMI removida: $ami_id"
        fi
    done
    
    # Limpar snapshots antigos
    log "Limpando snapshots antigos..."
    local old_snapshots
    old_snapshots=$(aws ec2 describe-snapshots \
        --owner-ids self \
        --filters "Name=tag:BackupType,Values=Automated" "Name=tag:InstanceId,Values=$INSTANCE_ID" \
        --query "Snapshots[?StartTime<'$cutoff_date'].SnapshotId" \
        --output text \
        --region "$REGION")
    
    for snapshot_id in $old_snapshots; do
        if [[ -n "$snapshot_id" ]]; then
            log "Removendo snapshot antigo: $snapshot_id"
            aws ec2 delete-snapshot --snapshot-id "$snapshot_id" --region "$REGION"
            success "Snapshot removido: $snapshot_id"
        fi
    done
    
    success "Limpeza de backups antigos concluída"
}

# Função para enviar para S3 (se configurado)
upload_to_s3() {
    if [[ -n "$S3_BUCKET" ]]; then
        log "Enviando logs para S3..."
        
        local s3_key="backup-logs/$INSTANCE_ID/$(date +%Y/%m/%d)/backup-$(date +%Y%m%d-%H%M%S).log"
        
        aws s3 cp "$LOG_FILE" "s3://$S3_BUCKET/$s3_key" --region "$REGION"
        
        if [[ $? -eq 0 ]]; then
            success "Logs enviados para S3: s3://$S3_BUCKET/$s3_key"
        else
            warning "Falha ao enviar logs para S3"
        fi
    fi
}

# Função para gerar relatório
generate_report() {
    log "Gerando relatório de backup..."
    
    local report_file="/tmp/backup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
========================================
RELATÓRIO DE BACKUP EC2
========================================
Data: $(date +%Y-%m-%d %H:%M:%S)
Instância: $INSTANCE_ID
Tipo de Backup: $BACKUP_TYPE
Nome do Backup: $BACKUP_NAME
Região: $REGION
Retenção: $BACKUP_RETENTION_DAYS dias

========================================
BACKUPS CRIADOS
========================================

EOF
    
    # Listar AMIs recentes
    if [[ "$BACKUP_TYPE" == "ami" ]] || [[ "$BACKUP_TYPE" == "both" ]]; then
        echo "AMIs:" >> "$report_file"
        aws ec2 describe-images \
            --owners self \
            --filters "Name=tag:InstanceId,Values=$INSTANCE_ID" \
            --query 'Images[?CreationDate>=`'$(date -d "1 day ago" +%Y-%m-%d)'`].[ImageId,Name,CreationDate]' \
            --output table >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    # Listar snapshots recentes
    if [[ "$BACKUP_TYPE" == "snapshot" ]] || [[ "$BACKUP_TYPE" == "both" ]]; then
        echo "Snapshots:" >> "$report_file"
        aws ec2 describe-snapshots \
            --owner-ids self \
            --filters "Name=tag:InstanceId,Values=$INSTANCE_ID" \
            --query 'Snapshots[?StartTime>=`'$(date -d "1 day ago" +%Y-%m-%d)'`].[SnapshotId,VolumeId,StartTime]' \
            --output table >> "$report_file"
    fi
    
    cat "$report_file"
    
    if [[ -n "$S3_BUCKET" ]]; then
        aws s3 cp "$report_file" "s3://$S3_BUCKET/backup-reports/$INSTANCE_ID/$(date +%Y/%m/%d)/" --region "$REGION"
    fi
    
    rm "$report_file"
}

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--instance-id)
            INSTANCE_ID="$2"
            shift 2
            ;;
        -b|--bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -d|--retention-days)
            BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        -n|--name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        -t|--type)
            BACKUP_TYPE="$2"
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
BACKUP_TYPE=${BACKUP_TYPE:-"both"}
BACKUP_NAME=${BACKUP_NAME:-"Backup-$INSTANCE_ID"}

# Função principal
main() {
    log "Iniciando script de backup para instância: $INSTANCE_ID"
    
    validate_dependencies
    validate_instance
    
    case "$BACKUP_TYPE" in
        "snapshot")
            create_snapshot
            ;;
        "ami")
            create_ami
            ;;
        "both")
            create_snapshot
            create_ami
            ;;
        *)
            error "Tipo de backup inválido: $BACKUP_TYPE"
            exit 1
            ;;
    esac
    
    cleanup_old_backups
    generate_report
    upload_to_s3
    
    success "Backup concluído com sucesso!"
}

# Verificar se INSTANCE_ID foi fornecido
if [[ -z "$INSTANCE_ID" ]]; then
    error "ID da instância é obrigatório (-i ou --instance-id)"
    show_help
    exit 1
fi

# Executar função principal
main "$@"
