# Plano de Continuidade de Negócios (PCN)

## 1. Visão Geral e Objetivo
Este documento estabelece o Plano de Continuidade de Negócios (PCN) da Solidary Tech. O objetivo central é garantir que a plataforma sobreviva a falhas catastróficas no cluster principal (EKS) ou na região primária da AWS (`us-east-1`), minimizando a perda de dados financeiros (doações) e o tempo de inatividade, assegurando a confiança das ONGs e dos doadores.

## 2. Decisão Estratégica e Análise de Custos
Para atender ao requisito de Disaster Recovery (DR), a engenharia avaliou duas abordagens:
* **Opção A:** Backup Cross-Region do estado do cluster (Velero) e dados (RDS Snapshots) combinados com recriação de infraestrutura sob demanda (*Cold Standby*).
* **Opção B:** Infraestrutura Ativo-Passivo (*Warm Standby*), mantendo um cluster "espelho" rodando em outra região.

A decisão fundamental da Solidary Tech foi a adoção da **Opção A (Multicloud/Cross-Region Backup com Velero)**.

**Justificativa Técnica e Financeira:** A escolha foi guiada por diversos fatores arquiteturais, onde **o custo operacional teve um peso relevante na decisão**. Manter um ambiente Ativo-Passivo (Opção B) exigiria o pagamento contínuo de um Control Plane do EKS, instâncias de Node Groups, Load Balancers e instâncias de banco de dados rodando de forma ociosa em uma segunda região, o que elevaria substancialmente o custo mensal da infraestrutura. A Opção A, aliada à forte automação de Infraestrutura como Código (Terraform/Terragrunt) integrada nos nossos pipelines de CI/CD, permite armazenar os backups de forma otimizada (S3) e levantar o ambiente de recuperação apenas no momento do desastre. Isso oferece o melhor equilíbrio entre resiliência técnica, governança e responsabilidade financeira.

## 3. Métricas Críticas: RTO e RPO
O sistema de **Doações** é o núcleo financeiro da plataforma. A perda destes dados impacta diretamente a credibilidade e a auditoria da Solidary Tech. Os microsserviços de ONGs e Voluntários possuem naturezas cadastrais, tolerando janelas levemente maiores.

* **Dados das Doações (Donation Service - PostgreSQL/SQS):**
  * **RPO (Recovery Point Objective): 15 minutos.**
    * *Definição:* Em caso de desastre, a perda máxima tolerável de histórico de transações é de 15 minutos.
    * *Garantia:* Alcançado através de backups contínuos de logs de transação (WAL) do RDS replicados para uma região secundária.
  * **RTO (Recovery Time Objective): 2 horas.**
    * *Definição:* Tempo máximo para a plataforma voltar a processar e exibir doações após a queda total.
    * *Garantia:* Tempo necessário para rodar o pipeline do Terraform na região de DR, restaurar o banco de dados a partir do snapshot e executar o `velero restore` para subir os pods e serviços.

* **Dados Cadastrais (NGO e Volunteer Services):**
  * **RPO: 24 horas**, alinhado à cadência do backup diário do Velero (Seção 4.1) — o `Schedule` cobre manifestos e estado do cluster nesta janela; **não há, hoje, backup de dados de aplicação (SQS/DynamoDB) cross-region automatizado**, apenas o estado do cluster via Velero.
  * **RTO: 4 horas.**

> **Nota de rastreabilidade:** o RPO de dados cadastrais foi ajustado de 12h para 24h para refletir a cadência real do `Schedule` do Velero (`backup-schedule.yaml`, execução diária às 03:00 UTC) implementado no projeto. Não existe, na infraestrutura atual, uma rotina de *snapshot* noturno independente para esses dados — o mecanismo de proteção vigente é o backup diário do Velero.

## 4. Estratégia de DR Prática (Implementação da Opção A)

A estratégia de recuperação baseia-se na separação entre Infraestrutura, Estado do Cluster e Dados Persistentes:

### 4.1. Backup do Estado do Cluster (Velero)

* O **Velero** atua no cluster EKS principal gerenciando os backups de estado.
* **Agendamento (`Schedule`):** configurado via [`backup-schedule.yaml`](../solidary-tech/eks/velero/backup-schedule.yaml), sincronizado por GitOps (ArgoCD, `recurse: true` sobre o diretório `eks/`), com execução diária às **03:00 UTC** — horário escolhido por estar fora do pico de doações.
* **Escopo do backup:** os namespaces `solidary-tech`, `monitoring`, `argocd` e `keda` — cobrindo a aplicação, a stack de observabilidade e os add-ons de cluster que sustentam o scaling (KEDA) e o próprio GitOps (ArgoCD), necessários para uma recuperação completa e não apenas da aplicação.
* **Retenção:** TTL de `720h0m0s` (**30 dias**) por backup no bucket.
* **Armazenamento Cross-Region:** o Velero é instalado com `--backup-location-config region=us-west-2`, enviando os backups para o bucket S3 `solidary-tech-velero-backups-dev` (ou equivalente por ambiente), provisionado pelo módulo Terraform `modules/velero` em uma região secundária (variável `dr_region`, *default* `us-west-2`) — distinta da região primária da infra (`us-east-1`).
* **Versionamento e retenção do bucket:** o bucket S3 de destino possui *versioning* habilitado e uma política de lifecycle que expira backups após **90 dias** — uma segunda camada de retenção, mais ampla que o TTL de 30 dias do próprio `Schedule`, funcionando como margem de segurança no armazenamento.
* **Ciclo de vida da infraestrutura do Velero:** automatizado via pipeline dedicado (job `velero-infra`, `terragrunt apply` sobre o módulo `velero`), que provisiona o bucket de destino **antes** da instalação do Velero no cluster — o job `cluster-addons` depende explicitamente de `velero-infra` para garantir essa ordem.
* **Identidade/permissões:** o Velero é instalado em modo `--no-secret`, autenticando via IRSA com a `LabRole` da conta AWS Lab (`--sa-annotations eks.amazonaws.com/role-arn=<LabRole>`), sem credenciais estáticas no cluster.

### 4.2. Backup de Dados (RDS/DynamoDB)

* Os bancos de dados (PostgreSQL gerenciados pelo Flyway) operam com políticas de retenção de snapshots automatizados e cópia *Cross-Region* ativada para a região secundária, sustentando o RPO de 15 minutos do `donation-service` (Seção 3).
* **DynamoDB (`volunteer-table`):** protegido pelo módulo `terraform/modules/aws_backup`, provisionado via `dynamodb-backup/dev/terragrunt.hcl`. O plano de backup executa diariamente às 03:00 UTC — mesma janela do Schedule do Velero — e realiza cópia cross-region para `us-west-2` (mesmo vault de DR), com retenção de 90 dias alinhada ao lifecycle do bucket S3 do Velero.
* **Gap remanescente:** a fila SQS (`donation-queue`) não possui backup cross-region equivalente — AWS Backup não suporta SQS nativamente. A perda de mensagens em trânsito no momento de um desastre deve ser avaliada dentro do RPO de 15 minutos declarado para o `donation-service`.

### 4.3. Procedimento de Recuperação (Runbook)

1. **Passo 1 (Infraestrutura):** em caso de queda primária, a equipe aciona o pipeline de CI/CD (`ci-infra.yml`) alterando temporariamente as variáveis de ambiente (como `TERRAGRUNT_DIR`) ou executando via `workflow_dispatch` apontando para a nova região (ex: `environments/dr`). O Terraform provisionará um novo EKS e a infraestrutura base limpa.
2. **Passo 2 (Bucket de Backup):** o job `velero-infra` garante que o bucket S3 de destino dos backups (região `us-west-2`) exista e esteja acessível antes de qualquer tentativa de restauração — pré-requisito do Passo 3.
3. **Passo 3 (Estado):** o job `cluster-addons` do pipeline reinstalará automaticamente o Velero no novo cluster utilizando os privilégios da `LabRole` (padrão do laboratório AWS), apontando para o mesmo bucket S3 onde os backups residem. Executa-se manualmente o comando `velero restore create --from-backup <ultimo-backup>` para reidratar o ecossistema (incluindo ArgoCD e KEDA, cobertos pelo escopo do `Schedule` — Seção 4.1) e os volumes persistentes, se aplicável.
4. **Passo 4 (Sincronização):** o ArgoCD, restaurado a partir do próprio backup do Velero, assume o controle final. Ele validará se o estado atual do GitOps (repositório `fase_5/tech_challenge/solidary-tech/eks`) está perfeitamente sincronizado com a infraestrutura recém-recuperada, restabelecendo o tráfego via novo Ingress NLB injetado pelo job `update-ingress-host`.
