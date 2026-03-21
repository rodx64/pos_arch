# Requisitos técnicos

## 1. Terraform

- [x] Substituir a criação manual da Fase 2 por código Terraform

    - [x] [Networking](../toggle-master-microservices/terraform/modules/vpc/): VPC, Subnets (Públicas e Privadas), Internet Gateway e Route Tables.
    - [x] [Cluster EKS](../toggle-master-microservices/terraform/modules/eks/): O cluster Kubernetes e seus Node Groups.
    o Atenção Academy: Lembre-se de associar a LabRole.
    - [x] Bancos de Dados:
    o 3 instâncias [RDS](../toggle-master-microservices/terraform/modules/rds/) (PostgreSQL).
    o 1 Cluster [ElastiCache Redis](../toggle-master-microservices/terraform/modules/redis/).
    o 1 Tabela [DynamoDB](../toggle-master-microservices/terraform/modules/dynamodb/) (ToggleMasterAnalytics).
    - [x] [Mensageria](../toggle-master-microservices/terraform/modules/sqs/): 1 Fila SQS.
    - [x] [Repositórios](../toggle-master-microservices/terraform/modules/ecr/): 5 repositórios no ECR (opcional via Terraform, mas recomendado).
    - [x] [Requisito de Estado](../toggle-master-microservices/terraform/backend/): O terraform.tfstate não pode ficar local. Configure o Backend Remoto usando um Bucket S3 (e opcionalmente a flag use_lockfile para Lock).

    - [x] Foi adicionado um modulo [root](../toggle-master-microservices/terraform/modules/root/) para integrar os módulos terraform.
    - [x] Foi adicionado uma estrutura de [environments](../toggle-master-microservices/terraform/environments/) para uso com terragrunt.

## 2. Pipeline de Integração Contínua (CI) & DevSecOps

- [x] Crie workflows para cada um dos 5 microsserviços ([Analytics](../../../.github/workflows/ci-analytics.yml), [Auth](../../../.github/workflows/ci-auth.yml), [Evaluation](../../../.github/workflows/ci-evaluation.yml), [Flag](../../../.github/workflows/ci-flag.yml), [Targeting](../../../.github/workflows/ci-targeting.yml)). A pipeline deve rodar a cada Pull Request e Push na Main. 

    Estágios:

    - [x] Build & Unit Test: Compilar o código e rodar testes unitários (se houver).
    - [x] Linter/Static Analysis: Rodar ferramentas de linting (ex: golangci-lint para Go, pylint/flake8 para Python).
    - [x] Security Scan (SAST & SCA):
        - [x] SCA (Software Composition Analysis): Verificar vulnerabilidades nas dependências (ex: usar Trivy em modo fs ou OWASP Dependency Check).
        - [x]  SAST (Static Application Security Testing): Verificar vulnerabilidades no código fonte (ex: SonarCloud gratuito ou gosec/bandit).
        - [x] Regra de Bloqueio: Se uma vulnerabilidade CRÍTICA for encontrada, a pipeline deve falhar e não prosseguir.
    - [x] Docker Build & Push:
        - [x] Construir a imagem Docker.
        - [x]  Rodar um scan de vulnerabilidades na imagem (Container Scan com Trivy).
        - [x]  Logar no AWS ECR.
        - [x]  Enviar a imagem para o ECR com a tag do commit hash (ex: v1.0.0-a1b2c3d).

## 3. Entrega Contínua (CD) & GitOps
Para o deploy, abandonaremos o push direto via CI. Vamos adotar o
GitOps.

- [x] [Repositório de GitOps](../toggle-master-microservices/eks/): Crie um repositório separado (ou uma pasta separada no monorepo) contendo apenas os manifestos Kubernetes (YAMLs) ou Helm Charts das aplicações.
- [ ] Instalação do ArgoCD: Instale o ArgoCD no seu cluster EKS (pode
usar Helm ou Terraform com provider helm/kubectl).
- [ ] Atualização Automática:
o Ao final do pipeline de CI (passo anterior), adicione um passo que
atualiza a tag da imagem no repositório de GitOps (alterando o
arquivo deployment.yaml com a nova tag da imagem gerada).
- [ ] Sync: Configure o ArgoCD para monitorar esse repositório e
sincronizar automaticamente as mudanças para o cluster EKS.
o Mostre a interface do ArgoCD gerenciando os 5 microsserviços.    
