# Tech Challenge - Fase 3

[Projeto](../toggle-master-microservices/) que engloba os conhecimentos obtidos em todas as disciplinas da fase 3.

## Components
- **Backend**: [path](../toggle-master-microservices/terraform/backend/)
- **Environments**: [path](../toggle-master-microservices/terraform/environments/)
- **Modules**: [dynamodb](../toggle-master-microservices/terraform/modules/dynamodb/), [ec2](../toggle-master-microservices/terraform/modules/ec2/), [ecr](../toggle-master-microservices/terraform/modules/ecr/), [eks](../toggle-master-microservices/terraform/modules/eks/), [k8s-secrets](../toggle-master-microservices/terraform/modules/k8s-secrets/), [rds](../toggle-master-microservices/terraform/modules/rds/), [redis](../toggle-master-microservices/terraform/modules/redis/), [root](../toggle-master-microservices/terraform/modules/root/), [s3](../toggle-master-microservices/terraform/modules/s3/), [sqs](../toggle-master-microservices/terraform/modules/sqs/), [vpc](../toggle-master-microservices/terraform/modules/vpc/)
- **Kubernetes**: [manifestos](../toggle-master-microservices/eks)
- **Workflows**: [path](../../../.github/workflows/)

## Execução

### 1. Manual

1.1. Backend
```
cd ../toggle-master-microservices/terraform/backend/
terraform init
terraform plan
terraform apply
```
1.2. Terragrunt
```
cd ../toggle-master-microservices/terraform/environments/dev/
terragrunt init 
terragrunt plan
terragrunt apply
```
### 2. CI/CD 

2.1. Infra

Abra um PR com as alterações no diretório [terraform](
../toggle-master-microservices/terraform/)

O workflow [ci-infra](../../../.github/workflows/ci-infra.yml) será responsável pelo trigger.

2.2. Serviços

Abra um PR com as alterações no diretório do respectivo serviço:
- [analytics-service](../toggle-master-microservices/analytics-service/)
- [auth-service](../toggle-master-microservices/auth-service/)
- [evaluation-service](../toggle-master-microservices/evaluation-service/)
- [flag-service](../toggle-master-microservices/flag-service/)
- [targeting-service](../toggle-master-microservices/targeting-service/)

Os workflows respectivos que serão responsáveis pelo trigger (tem dependência com a infra criada):
- [ci-analytics](../../../.github/workflows/ci-analytics.yml)
- [ci-auth](../../../.github/workflows/ci-auth.yml)
- [ci-evaluation](../../../.github/workflows/ci-evaluation.yml)
- [ci-flag](../../../.github/workflows/ci-flag.yml)
- [ci-targeting](../../../.github/workflows/ci-targeting.yml)
