# Relatório FinOps: Projeção de Custos e Otimização Estratégica
## Solidary Tech — Ambientes: DEV (Local), HOM e PRO

> **Nota sobre o status real do projeto:** hoje, na AWS, **só existe o ambiente `dev`** provisionado (via Terragrunt/Terraform, IAM Role fixa de Lab). As colunas **HOM** e **PRO** abaixo são **simulações** para fins de planejamento financeiro — ainda não foram provisionadas.

### 1. Forecast (Projeção de Custos Mensais por Ambiente)

> *Como o orçamento da ONG é limitado, cada centavo conta* — por isso este forecast não compara apenas HOM e PRO entre si: a Seção 1.1 isola o quanto a decisão arquitetural de DEV local-first já economiza **antes mesmo de qualquer recurso de produção existir**, e a Seção 2.B mostra como HOM, ao ser provisionado **por janela de homologação** (sob demanda, e não 24/7), reduz seu custo a uma fração do que custaria um ambiente permanentemente ligado.

| Componente | DEV (Local-First) | HOM (Homologação — sob demanda, simulado) | PRO (Produção — simulado) |
| :--- | :--- | :--- | :--- |
| **Amazon EKS (Control Plane)** | $0,00 (Kind / k3d) | $3,20 (32h/mês de janelas ativas) | $73,00 (1 cluster, always-on) |
| **Computação (Node Group)** | $0,00 (Docker Engine) | $1,20 (3x `t3.medium` 100% Spot, apenas durante a janela) | $100,20 (3x `t3.medium` On-Demand + burst Spot) |
| **Bastion (EC2)** | $0,00 | $0,67 (1x `t3.small`, apenas durante a janela) | $15,18 (1x `t3.small`, always-on) |
| **Bancos de Dados (RDS)** | $0,00 (Postgres Local) | $1,02 (2x `db.t4g.micro` Single-AZ, apenas durante a janela) | $198,55 (2x `db.t3.medium` Multi-AZ) |
| **Rede (NAT Gateway)** | $0,00 | $1,44 (1x, apenas durante a janela, base sem tráfego) | $48,85 (1x, base + processamento estimado) |
| **Mensageria / NoSQL (SQS + DynamoDB)** | $0,00 (LocalStack) | $1,00 (baixo volume de testes, billing por uso) | $12,00 (volume real) |
| **Total Mensal Estimado** | **$0,00** | **~$8,53** | **~$447,80** |

> **Metodologia:** valores calculados a partir das taxas públicas On-Demand da AWS para `us-east-1`, 730h/mês (EKS control plane $0,10/h; `t3.medium` $0,0416/h; `t3.small` $0,0208/h; `db.t4g.micro` $0,016/h; NAT Gateway $0,045/h base). PRO assume `db.t3.medium` Multi-AZ (dobra o custo de instância), node group misto (baseline On-Demand + burst Spot) e infraestrutura always-on. **HOM** assume uma topologia idêntica à de PRO em termos de Spot/desconto, mas billada apenas pelas horas em que a infraestrutura efetivamente existe — ver metodologia detalhada na Seção 2.B. Esses números são estimativas de planejamento, não uma cotação oficial — use a AWS Pricing Calculator para validar antes de qualquer compromisso orçamentário real.

### 1.1. DEV Local-First vs. DEV na AWS: o que a estratégia local evita gastar

A tabela abaixo isola, especificamente para o ambiente de desenvolvimento, a diferença entre a estratégia adotada hoje (100% local, custo zero) e o cenário hipotético de rodar a mesma topologia atual do `dev` na nuvem, *always-on*, durante a fase de desenvolvimento:

| Componente | DEV (Local-First) | DEV (AWS) — *cenário comparativo, always-on* |
| :--- | :--- | :--- |
| **Amazon EKS (Control Plane)** | $0,00 (Kind / k3d) | $73,00 (1 cluster) |
| **Computação (Node Group)** | $0,00 (Docker Engine) | $91,10 (3x `t3.medium` On-Demand) |
| **Bastion (EC2)** | $0,00 | $15,18 (1x `t3.small`) |
| **Bancos de Dados (RDS)** | $0,00 (Postgres Local) | $23,35 (2x `db.t4g.micro` Single-AZ) |
| **Rede (NAT Gateway)** | $0,00 | $32,85 (1x, base sem tráfego) |
| **Mensageria / NoSQL (SQS + DynamoDB)** | $0,00 (LocalStack) | $1,50 (baixo volume) |
| **Total Mensal Estimado** | **$0,00** | **~$237,00** |

A diferença entre as duas colunas **não é teórica**: é o valor que a ONG deixaria de gastar todos os meses, só na fase de desenvolvimento, caso a equipe não tivesse adotado a estratégia local-first (LocalStack + Kind + Docker Compose) descrita na Seção 2.C.

- **DEV (Local-First):** $0,00/mês
- **DEV (AWS), mesma topologia, always-on:** ~$237,00/mês
- **Economia mensal só nesta fase:** ~$237,00 (100% do que seria gasto)
- **Projeção anual economizada apenas em DEV:** ~$2.844,00

Essa comparação é o argumento mais direto para a frase "cada centavo conta": antes de discutir Savings Plans ou Spot em produção, a primeira e mais barata decisão de FinOps já está em vigor — <u>não provisionar nada que não precise existir ainda</u>.

---

### 2. Estratégias de Otimização e Governança por Ambiente

Para garantir a viabilidade financeira da ONG sem sacrificar a resiliência tecnológica, as seguintes políticas de FinOps são aplicadas com regras específicas por ambiente:

#### A. Ambiente de Produção (PRO) — *Foco: Resiliência e Eficiência de Longo Prazo* `(simulado)`
Em produção, a disponibilidade (SLO) é inegociável. As otimizações focam em compromissos de uso e arquiteturas tolerantes a falhas.
* **Arquitetura Mista de Computação (On-Demand + Spot):** o Node Group principal roda sob demanda para garantir o baseline de requisições. O escalonamento horizontal para picos de tráfego utiliza um segundo Node Group 100% Spot. O [`aws-node-termination-handler`](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/automate-deployment-of-node-termination-handler-in-amazon-eks-by-using-a-ci-cd-pipeline.html) garante o cordon e drain seguro dos pods antes da interrupção da instância pela AWS.
* **Compute Savings Plans:** contratação de [Savings Plans](https://docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html) de 1 ou 3 anos para a capacidade computacional base, reduzindo o custo da camada fixa em até **50%**.
* **RDS Reserved Instances:** compra de [instâncias reservadas para os bancos de dados](https://aws.amazon.com/rds/reserved-instances/) Multi-AZ, gerando economia previsível para o estado persistente da aplicação.

#### B. Ambiente de Homologação (HOM) — *Foco: Provisionamento por Janela (Ephemeral Infra)*

Diferente de produção, o ambiente de homologação não precisa existir continuamente: ele só precisa estar de pé durante as **janelas de homologação** — períodos pontuais em que o time efetivamente testa uma release antes do go-live. Toda a infraestrutura de HOM (cluster EKS, node group, bastion, RDS e NAT Gateway) é provisionada e destruída via **Terraform/Terragrunt** (`terragrunt apply` / `terragrunt destroy` sobre o módulo `root`), e não mantida ligada em horário comercial fixo como em uma abordagem de simples *autoscaling schedule*.

* **Infraestrutura efêmera via IaC:** uma pipeline de CI/CD (ex: GitHub Actions, disparada manualmente ou agendada antes de cada release) executa `terragrunt run-all apply` no ambiente `hom` no início da janela e `terragrunt run-all destroy` ao final, eliminando 100% do custo fora do período de testes — incluindo o Control Plane do EKS, que normalmente é cobrado mesmo com o Node Group zerado.
* **100% Spot Instances durante a janela:** enquanto a infraestrutura existe, o Node Group do EKS opera em [instâncias Spot](https://docs.aws.amazon.com/pt_br/AWSEC2/latest/UserGuide/using-spot-instances.html), somando até **70%** de economia em computação sobre o já reduzido custo da janela.
* **Premissa de uso adotada no forecast:** a tabela da Seção 1 assume **32 horas de janelas de homologação por mês** (ex: 2 ciclos de testes por semana, de ~4h cada), parâmetro facilmente ajustável bastando reaplicar a fórmula `custo_hora_recurso × horas_da_janela` para o cadência real adotada pelo time.
* **Comparativo com o modelo anterior (always-on agendado):** se o ambiente ficasse de pé em horário comercial fixo (ex: 06h–20h, todos os dias), o custo mensal estimado seria de ~$173,75 — ainda assim, o modelo por janela representa uma economia adicional de **~95%** sobre essa alternativa, pois reduz as horas de operação de ~420h/mês para ~32h/mês.

#### C. Ambiente de Desenvolvimento (DEV) — *Foco: Local-First (Shift-Left FinOps) e Custo Zero* `(configurado no projeto)`
A estratégia mais agressiva de FinOps é não provisionar recursos em nuvem pública quando não é estritamente necessário. O ambiente de DEV na AWS foi totalmente descontinuado. Toda a engenharia, testes de integração e validação de infraestrutura rodam diretamente nas máquinas dos desenvolvedores utilizando ferramentas free:
* **Emulação de Nuvem AWS ([LocalStack](https://www.localstack.cloud/) / [Ministack](https://ministack.org/)):** os serviços SQS (`donation-queue`) e DynamoDB (`volunteer-table`) rodam localmente via LocalStack ([`docker-compose.yml` + `init-aws.sh`](../solidary-tech/local/)), permitindo o desenvolvimento com o AWS SDK sem bilhetagem na conta da AWS.
* **Validação de IaC Local (Terraform / Terragrunt / [Open Tofu](https://opentofu.org/)):** a esteira de Infraestrutura como Código usa o recurso `mock_outputs` do Terragrunt (ver [`observability/dev/terragrunt.hcl`](../solidary-tech/observability/dev/terragrunt.hcl)) para que comandos de `plan`/`validate` rodem sem depender de estado remoto real do EKS.
* **Infraestrutura Local Efêmera:** o PostgreSQL sobe via `docker-compose` ([`local/docker-compose.yml`](../solidary-tech/local/docker-compose.yml)), eliminando custos de instâncias RDS permanentemente ligadas durante o desenvolvimento.

> A Seção 1.1 quantifica exatamente a contrapartida financeira do que esta seção descreve: o custo que essas decisões evitam, mês a mês.

---

### 3. Recomendação Prática de Otimização Nativa de Nuvem

**AWS Cost Anomaly Detection + Cost Allocation Tags ativas no Billing.**

Com a política de tagging implementada (módulo de tagging, Terraform), o próximo passo nativo de cloud é:

1. Ativar as tags `Project`, `Environment` e `CostCenter` como **Cost Allocation Tags** no AWS Billing Console — ativação manual obrigatória mesmo após o recurso ser tagueado, já que a AWS não inclui tags no Cost Explorer automaticamente.
2. Configurar o **AWS Cost Anomaly Detection** com monitor segmentado por `CostCenter=NGO-Core`, gerando alertas automáticos via SNS/e-mail se o gasto diário desviar do padrão histórico — essencial para uma ONG sem capacidade de revisar billing manualmente todos os dias. Isso é particularmente útil no modelo de HOM por janela: qualquer cobrança fora dos períodos esperados de homologação (ex: um `destroy` que falhou silenciosamente) é sinalizada rapidamente.

Essa combinação fecha o ciclo de FinOps: a tag garante a **rastreabilidade** (de onde vem o custo) e o Anomaly Detection garante a **reação rápida** (quando algo sai do esperado), sem custo adicional relevante de ferramenta.

---

### 4. Fontes e Referências de Preços

Os valores usados neste forecast foram baseados nas tarifas públicas On-Demand da AWS para a região `us-east-1`, consultadas em junho de 2026. Use estas fontes para validar ou atualizar os números antes de qualquer decisão orçamentária real:

| Componente | Taxa usada | Fonte |
| :--- | :--- | :--- |
| EKS Control Plane | $0,10/hora por cluster | [Amazon EKS Pricing](https://aws.amazon.com/eks/pricing/) |
| EC2 `t3.medium` / `t3.small` (On-Demand) | $0,0416/h e $0,0208/h | [Amazon EC2 On-Demand Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) · [EC2 T3 Instances](https://aws.amazon.com/ec2/instance-types/t3/) |
| RDS `db.t4g.micro` (PostgreSQL, Single-AZ) | $0,016/h | [Amazon RDS for PostgreSQL Pricing](https://aws.amazon.com/rds/postgresql/pricing/) |
| NAT Gateway | $0,045/hora + $0,045/GB processado | [Pricing for NAT gateways — Amazon VPC Docs](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-pricing.html) · [Amazon VPC Pricing](https://aws.amazon.com/vpc/pricing/) |
| Spot Instances (desconto médio ~70% sobre On-Demand) | — | [AWS Pricing Calculator](https://calculator.aws/) |
| RDS Multi-AZ (dobra o custo de instância) | — | [Amazon RDS for PostgreSQL Pricing](https://aws.amazon.com/rds/postgresql/pricing/) |
| Cost Allocation Tags (ativação manual no Billing) | — | [Using AWS cost allocation tags — AWS Billing Docs](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html) |
| AWS Cost Anomaly Detection | — | [AWS Cost Anomaly Detection — página oficial](https://aws.amazon.com/aws-cost-management/aws-cost-anomaly-detection/) |

> **Ferramenta de validação recomendada:** para conferir ou atualizar qualquer valor deste relatório, use a [AWS Pricing Calculator](https://calculator.aws/), que permite montar a estimativa completa (incluindo storage, IOPS e tráfego) com base na configuração exata de cada recurso.

**Documentação Terraform/Terragrunt usada como referência para o módulo de tagging e para o modelo de infraestrutura efêmera:**

| Recurso | Fonte |
| :--- | :--- |
| `default_tags` no provider AWS (e a exceção documentada para `aws_autoscaling_group`) | [Terraform Registry — AWS Provider docs (seção default_tags)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) · [HashiCorp — Configure default tags for AWS resources (tutorial)](https://developer.hashicorp.com/terraform/tutorials/aws/aws-default-tags) |
| Limitações de herança de tags em Auto Scaling Groups | [AWS — Tagging your Auto Scaling groups and instances](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) |
| Módulo `terraform-aws-modules/eks/aws` (usado em `modules/eks`) | [Registry: terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) |
| Módulo `terraform-aws-modules/rds/aws` (usado em `modules/rds`) | [Registry: terraform-aws-modules/rds/aws](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest) |
| Terragrunt `run-all apply` / `run-all destroy` (base do modelo de infraestrutura efêmera de HOM) | [Terragrunt Docs — CLI commands](https://terragrunt.gruntwork.io/docs/reference/cli/) |
| Terragrunt `mock_outputs` (usado em `dev/terragrunt.hcl`) | [Terragrunt Docs — Mocking outputs](https://terragrunt.gruntwork.io/docs/features/units/#unit-dependencies) |
