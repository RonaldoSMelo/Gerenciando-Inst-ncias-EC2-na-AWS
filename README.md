# 🚀 Desafio: Gerenciamento de Instâncias EC2 na AWS

## 📋 Descrição do Projeto

Este repositório documenta minha jornada de aprendizado sobre gerenciamento de instâncias EC2 na Amazon Web Services (AWS), consolidando os conhecimentos adquiridos durante o curso da DIO (Digital Innovation One).

## 🎯 Objetivos de Aprendizagem

- [x] Aplicar conceitos de EC2 em ambiente prático
- [x] Documentar processos técnicos de forma clara e estruturada
- [x] Utilizar GitHub para compartilhamento de documentação técnica
- [x] Criar material de apoio para estudos futuros

## 📚 Conteúdo do Repositório

### 📁 Estrutura de Arquivos

```
├── README.md                 # Este arquivo - documentação principal
├── Desafio.drawio           # Diagramas da arquitetura EC2
├── images/                  # Screenshots e imagens
│   ├── ec2-dashboard.png
│   ├── security-groups.png
│   └── instance-monitoring.png
├── docs/                    # Documentação adicional
│   ├── comandos-aws-cli.md
│   ├── configuracoes-seguranca.md
│   └── troubleshooting.md
└── scripts/                 # Scripts úteis
    ├── launch-instance.sh
    └── backup-script.sh
```

## 🔧 Conceitos Aplicados

### 1. **Criação e Configuração de Instâncias**
- Seleção de AMI (Amazon Machine Image)
- Escolha de tipos de instância
- Configuração de storage (EBS)
- Tags e nomenclatura

### 2. **Segurança e Acesso**
- Security Groups
- Key Pairs
- IAM Roles
- VPC e Subnets

### 3. **Monitoramento e Manutenção**
- CloudWatch
- Logs de sistema
- Métricas de performance
- Alertas e notificações

### 4. **Backup e Recuperação**
- Snapshots EBS
- AMI personalizadas
- Estratégias de backup

## 🛠️ Tecnologias Utilizadas

- **AWS EC2** - Elastic Compute Cloud
- **AWS VPC** - Virtual Private Cloud
- **AWS IAM** - Identity and Access Management
- **AWS CloudWatch** - Monitoramento
- **AWS CLI** - Interface de linha de comando
- **SSH** - Acesso remoto
- **Linux** - Sistema operacional das instâncias

## 📊 Diagramas e Arquitetura

Os diagramas detalhados da arquitetura podem ser visualizados no arquivo `Desafio.drawio`, incluindo:

- Fluxo de criação de instâncias
- Arquitetura de rede (VPC, Subnets, Security Groups)
- Estratégia de monitoramento
- Processo de backup

## 🚀 Como Executar

### Pré-requisitos
- Conta AWS ativa
- AWS CLI configurado
- Chaves SSH configuradas

### Passos Básicos
1. Configure suas credenciais AWS
2. Execute os scripts de criação de instâncias
3. Configure o monitoramento
4. Implemente estratégias de backup

## 📝 Lições Aprendidas

### ✅ Sucessos
- Criação eficiente de instâncias com configurações otimizadas
- Implementação de segurança robusta com Security Groups
- Monitoramento proativo com CloudWatch
- Automatização de processos com scripts

### 🔄 Desafios e Soluções
- **Desafio**: Configuração inicial de Security Groups
  - **Solução**: Documentação detalhada de regras e boas práticas

- **Desafio**: Otimização de custos
  - **Solução**: Implementação de instâncias spot e auto-scaling

## 📚 Recursos Úteis

- [Documentação Oficial AWS EC2](https://docs.aws.amazon.com/ec2/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Security Best Practices](https://aws.amazon.com/security/security-resources/)

## 🤝 Contribuições

Este repositório é parte de um projeto educacional da DIO. Sugestões e melhorias são bem-vindas!

## 📄 Licença

Este projeto é para fins educacionais e está sob a licença MIT.

---

**Desenvolvido por**: Ronaldo Melo
**Curso**: DIO - Digital Innovation One  
**Data**: 18/10/2025
**Versão**: 1.0.0
