# backend.tf
# Configuração do backend remoto para armazenar o state no S3

terraform {
  backend "s3" {
    bucket         = "meu-bucket-terraform-state"    # Substitua pelo nome do seu bucket S3
    key            = "infra/aula2/terraform.tfstate" # Caminho do arquivo state
    region         = "us-east-1"                     # Região do bucket
    dynamodb_table = "terraform-locks"               # Tabela DynamoDB usada para lock
    encrypt        = true                            # Ativar criptografia do state
  }
}
