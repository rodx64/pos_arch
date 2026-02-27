# ==============================
# variables.tf - Variáveis globais
# ==============================

# Nome do ambiente (ex: dev, prod)
variable "environment_name" {
  description = "Nome do ambiente (ex: dev, prod)"
  type        = string
  default     = "dev"
}

# AMI usada para instância
variable "ami_id" {
  description = "AMI a ser usada nas instâncias"
  type        = string
  default     = "ami-0360c520857e3138f"
}

# Tipo de instância
variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

# CIDR liberado para acesso SSH (ex: 0.0.0.0/0 para liberar geral)
variable "ssh_access_cidr" {
  description = "CIDR permitido para acesso SSH"
  type        = string
  default     = "0.0.0.0/0"
}

# ID da VPC existente (não cria nova VPC)
variable "vpc_id" {
  description = "ID da VPC existente onde os recursos serão criados"
  type        = string
  default    = "vpc-09dabb72414674da8"
}

# ID da Subnet existente (não cria nova Subnet)
variable "subnet_id" {
  description = "ID da Subnet existente dentro da VPC"
  type        = string
  default     = "subnet-0e00ce0cb488df91f"
}

variable "labRole" {
  default = "arn:aws:iam::896497467373:role/LabRole"
}

