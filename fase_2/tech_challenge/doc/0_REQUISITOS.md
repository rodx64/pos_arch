# Requisitos técnicos

## 1. Análise e Conteinerização (Docker)

- [x] Criar um Dockerfile otimizado para cada um dos 5
microsserviços
  - [x] [analytics-service][analytics]
  - [x] [auth-service][auth]
  - [x] [evaluation-service][evaluation]
  - [x] [flag-service][flag]
  - [x] [targeting-service][targeting]

[analytics]: ../toggle-master-microservices/analytics-service/Dockerfile
[auth]: ../toggle-master-microservices/auth-service/Dockerfile
[evaluation]: ../toggle-master-microservices/evaluation-service/Dockerfile
[flag]: ../toggle-master-microservices/flag-service/Dockerfile
[targeting]: ../toggle-master-microservices/targeting-service/Dockerfile

- [x] Criar um único arquivo docker-compose.yml na raiz
do projeto que suba todos os microsserviços e os bancos de
dados locais
  - [x] [docker-compose][compose]

[compose]: ../toggle-master-microservices/docker-compose.yaml

🚀 Adicionado Localstack para execução local

## 2. Provisionando a Infraestrutura na Nuvem (Console AWS e eksctl)

- [ ] Cluster Kubernetes - Opção A (via WS Academy)
  - [ ] Crie 1 cluster AWS EKS usando o Console da AWS. Não use o
    eksctl create cluster.
  - [ ] Cluster Role: Quando solicitado, selecione a role existente LabRole.
  - [ ] Crie um Managed Node Group (pelo console).
  - [ ] Node IAM Role: Quando solicitado, selecione a LabRole existente.
  - [ ] Configuração de Auto Scaling: Defina a configuração de
    escalabilidade do grupo de nós (ex: Mínimo=1, Desejado=2,
    Máximo=4 instâncias)

- [ ] Registro de Contêineres (ECR)
  - [ ] Crie 5 (cinco) repositórios no AWS ECR, um para cada microsserviço
(ex: auth-service, flag-service, etc.).
  - [ ] Publique as imagens Docker que você criou na etapa 1 para seus
respectivos repositórios no ECR.

- [ ] Bancos de Dados Relacionais (RDS)
  - [ ] Crie 3 (três) instâncias de banco de dados AWS RDS for PostgreSQL
independentes.
    - [ ] Recurso 1 (RDS): Para o auth-service.
    - [ ] Recurso 2 (RDS): Para o flag-service.
    - [ ] Recurso 3 (RDS): Para o targeting-service.
  - [ ] Crie o ElastiCache: Para o evaluation-service.

- [ ] Banco de Dados NoSQL (DynamoDB):
  - [ ] Crie 1 (uma) tabela no AWS DynamoDB.
  - [ ] Recurso 5 (DynamoDB): Para o analytics-service.

- [ ] Fila de Mensagens (SQS):
  - [ ] Crie 1 (uma) fila AWS SQS (do tipo Standard).
  - [ ] Recurso 6 (SQS): Para ser usada pelo evaluation-service (que produz
mensagens) e pelo analytics-service (que consome as mensagens).

## 3. Configurando o Cluster (Kubernetes)

### Metrics Server - Comum a ambas as opções

- [ ] Instale o Metrics Server no seu cluster. Ele é necessário para o HPA
funcionar.

    (Usar kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/
    releases/latest/download/components.yaml).

### Nginx Ingress Controller - Opção A (via AWS Academy)

- [ ] Instale o Nginx Ingress Controller (via Helm ou kubectl apply). Como seus nós têm a LabRole, o Nginx Controller terá permissão para criar um Application Load Balancer (ALB) ou Network Load Balancer (NLB) na AWS.

## 4. Orquestração e Implantação (Manifestos) - Comum a ambas as opções (A e B)

- [ ] Manifestos Básicos: Crie os arquivos YAML para cada um dos 5 microsserviços:
  1. Namespaces (separadores lógicos para aplicações).
  2. Deployment (para gerenciar os Pods, garantindo que eles usem as
  imagens do ECR).
  3. Service (do tipo ClusterIP).
  4. Secrets (para injetar com segurança todas as senhas, endpoints e
  chaves de acesso dos recursos que você criou na Etapa 2).
  5. ConfigMap (para injetar URLs de serviços internos e outros dados).

- [ ] Acesso Externo (Ingress)
  1. Crie um manifesto Ingress que defina as regras de roteamento (ex: /auth
vai para o auth-service, /flags para o flag-service, etc.).

- [ ] Boas práticas de orquestração:
  - [ ] Use sempre Requests e Limits nos Deployments para evitar
problemas com o Node.
  - [ ] Garanta que as secrets sempre estarão em base64.
  - [ ] Use sempre Readiness e/ou LivenessProbe sempre que possível
  - [ ] Crie sempre suas aplicações separando por Namespaces.

## 5. Configurando a Escalabilidade

- [ ] Horizontal Pod Autoscaler (HPA) - Requisito Mínimo (Opção A)

- Esta é a solução para o Academy. Quando a fila SQS encher, este serviço processará mais mensagens, sua CPU aumentará, e o HPA adicionará mais pods.
  - [ ] Crie um manifesto HorizontalPodAutoscaler para o evaluation-service baseado na
utilização média de CPU (ex: targetCPUUtilizationPercentage: 70).
  - [ ] Crie um manifesto HorizontalPodAutoscaler para o analytics-service
também baseado na utilização média de CPU.
