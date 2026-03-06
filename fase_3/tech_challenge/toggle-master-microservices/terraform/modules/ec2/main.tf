# Instância EC2 em sub-rede privada para acesso bastion
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.env}-app-sg"
  description = "App security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "${var.project_name}-${var.env}-app-sg"
    Project = "${var.project_name}"
  }
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = { 
    Name = "${var.project_name}-${var.env}-bastion" 
    Project = var.project_name
  }
}
