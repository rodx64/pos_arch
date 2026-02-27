# main.tf
# Definição do provedor AWS
provider "aws" {
  region = var.aws_region
}

# Consome módulo local de rede
module "network" {
  source   = "./modules/network"
  vpc_cidr = var.vpc_cidr
  subnets  = var.subnets
}

# Exemplo de uso do count para criar múltiplas instâncias idênticas
resource "aws_instance" "web" {
  count         = 2
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = element(module.network.subnet_ids, 0)

  tags = {
    Name = "web-${count.index}"
  }
}

# Exemplo de uso do for_each para criar instâncias diferentes
resource "aws_instance" "apps" {
  for_each      = var.instances
  ami           = var.ami_id
  instance_type = each.value
  subnet_id     = element(module.network.subnet_ids, 0)

  tags = {
    Name = "app-${each.key}"
  }
}

# Exemplo de uso do operador ternário para mudar configuração dependendo do ambiente
resource "aws_instance" "conditional" {
  ami           = var.ami_id
  instance_type = var.is_production ? "t3.large" : "t2.micro"
  subnet_id     = element(module.network.subnet_ids, 0)

  tags = {
    Name = var.is_production ? "prod-app" : "dev-app"
  }
}

# Exemplo de recurso opcional criado condicionalmente com for_each
resource "aws_nat_gateway" "this" {
  for_each      = var.enable_nat ? toset(["active"]) : toset([])
  allocation_id = aws_eip.nat.id
  subnet_id     = element(module.network.subnet_ids, 0)
}

# Elastic IP associado ao NAT Gateway (se criado)
resource "aws_eip" "nat" {
  vpc = true
}

# Exemplo de dynamic block para criar regras de segurança de forma dinâmica
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = module.network.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # Regra de saída permitindo todo o tráfego
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Exemplo de consumo de módulo público do Terraform Registry
module "public_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "public-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]

  enable_nat_gateway = false
}
