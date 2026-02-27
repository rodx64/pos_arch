# main.tf
# Definindo o provider AWS e criando uma VPC, Subnet e instância EC2

provider "aws" {
  region = var.aws_region
}

# Criar uma VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "aula2-vpc"
  }
}

# Criar uma Subnet
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = element(var.zones, 0)
  tags = {
    Name = "aula2-subnet"
  }
}

# Criar uma instância EC2
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet.id

  tags = {
    Name = "aula2-ec2"
  }
}
