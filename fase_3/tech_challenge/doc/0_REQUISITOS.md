# Requisitos técnicos

## 1. Terraform

- [ ] Substituir a criação manual da Fase 2 por código Terraform

    - [x] Networking: VPC, Subnets (Públicas e Privadas), Internet Gateway e Route Tables.
    - [x] Cluster EKS: O cluster Kubernetes e seus Node Groups.
    o Atenção Academy: Lembre-se de associar a LabRole.
    - [ ] Bancos de Dados:
    o 3 instâncias RDS (PostgreSQL).
    o 1 Cluster ElastiCache (Redis).
    o 1 Tabela DynamoDB (ToggleMasterAnalytics).
    - [ ] Mensageria: 1 Fila SQS.
    - [ ] Repositórios: 5 repositórios no ECR (opcional via Terraform, mas recomendado).
    - [ ] Requisito de Estado: O terraform.tfstate não pode ficar local. Configure o Backend Remoto usando um Bucket S3 (e opcionalmente a flag use_lockfile para Lock).

## 2. Pipeline de Integração Contínua (CI) & DevSecOps

- [ ] Crie workflows para cada um dos 5 microsserviços. A pipeline deve rodar a cada Pull Request e Push na Main. 
Estágios:

    - [ ] Build & Unit Test: Compilar o código e rodar testes unitários (se houver).
    - [ ] Linter/Static Analysis: Rodar ferramentas de linting (ex: golangci-lint para Go, pylint/flake8 para Python).
    - [ ] Security Scan (SAST & SCA):
        - [ ] SCA (Software Composition Analysis): Verificar vulnerabilidades nas dependências (ex: usar Trivy em modo fs ou OWASP Dependency Check).
        - [ ]  SAST (Static Application Security Testing): Verificar vulnerabilidades no código fonte (ex: SonarCloud gratuito ou gosec/bandit).
        - [ ] Regra de Bloqueio: Se uma vulnerabilidade CRÍTICA for encontrada, a pipeline deve falhar e não prosseguir.
    - [ ] Docker Build & Push:
        - [ ] Construir a imagem Docker.
        - [ ]  Rodar um scan de vulnerabilidades na imagem (Container Scan com Trivy).
        - [ ]  Logar no AWS ECR.
        - [ ]  Enviar a imagem para o ECR com a tag do commit hash (ex: v1.0.0-a1b2c3d).

## 3. Entrega Contínua (CD) & GitOps
Para o deploy, abandonaremos o push direto via CI. Vamos adotar o
GitOps.

- [ ] Repositório de GitOps: Crie um repositório separado (ou uma pasta separada no monorepo) contendo apenas os manifestos Kubernetes (YAMLs) ou Helm Charts das aplicações.
