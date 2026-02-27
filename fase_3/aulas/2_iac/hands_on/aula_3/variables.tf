# variables.tf
# Região AWS
variable "aws_region" {
  default = "us-east-1"
}

# ID da AMI a ser usada
variable "ami_id" {
  description = "AMI utilizada nas instâncias"
  type        = string
}

# CIDR da VPC principal
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# Subnets (zona -> CIDR)
variable "subnets" {
  type = map(string)
  default = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }
}

# Instâncias a serem criadas com for_each
variable "instances" {
  type = map(string)
  default = {
    "api"   = "t2.micro"
    "cache" = "t3.small"
  }
}

# Flag de ambiente
variable "is_production" {
  default = false
}

# Habilita ou não criação de NAT Gateway
variable "enable_nat" {
  default = false
}

# Regras de segurança a serem aplicadas dinamicamente
variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
