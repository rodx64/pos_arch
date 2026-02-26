# ==============================
# main.tf - Exemplo de EC2 com SG
# ==============================
# Este arquivo cria:
# - Um Security Group atrelado à VPC existente
# - Uma instância EC2 dentro da Subnet especificada
# Obs: Não cria VPC nem Subnet, devem ser informados os IDs já existentes.

resource "aws_security_group" "instance" {
  name        = "instance-sg-${var.environment_name}"
  description = "Security group for the EC2 instances"
  vpc_id      = var.vpc_id 

  # Regra de entrada para SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }

  # Regra de saída (liberando todo tráfego)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "instance-sg-${var.environment_name}"
    Environment = var.environment_name
  }
}

# Criação da instância EC2
resource "aws_instance" "example" {
  ami                         = var.ami_id        # AMI deve existir na região
  instance_type               = var.instance_type # Tipo da instância (ex: t2.micro)
  subnet_id                   = var.subnet_id     # Subnet existente na VPC
  vpc_security_group_ids      = [aws_security_group.instance.id]
  associate_public_ip_address = true              # Atribui IP público

  tags = {
    Name        = "example-${var.environment_name}"
    Environment = var.environment_name
  }
}
