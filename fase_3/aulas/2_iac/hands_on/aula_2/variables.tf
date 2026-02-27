# variables.tf
# Declaração de variáveis com diferentes tipos

variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI da instância EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "Bloco CIDR para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Bloco CIDR para a Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Conjunto de tags únicas"
  type        = set(string)
  default     = ["dev", "terraform"]
}

variable "app_config" {
  description = "Configuração da aplicação"
  type = object({
    name     = string
    version  = string
    replicas = number
  })
  default = {
    name     = "minha-app"
    version  = "1.0.0"
    replicas = 2
  }
}
