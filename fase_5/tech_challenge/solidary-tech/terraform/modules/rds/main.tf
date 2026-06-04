module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier        = var.identifier
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  family               = var.family
  major_engine_version = var.engine_version
  db_name              = var.db_name
  username             = var.db_user
  port                 = tostring(var.port)

  vpc_security_group_ids = [aws_security_group.allow_bastion.id]
  subnet_ids             = var.private_subnet_ids
  create_db_subnet_group = true

  deletion_protection                 = false
  iam_database_authentication_enabled = true
  manage_master_user_password         = true

  tags = local.common_tags
}

resource "aws_security_group" "allow_bastion" {
  name        = "${var.project_name}-${var.env}-${var.identifier}-rds-sg"
  description = "Acesso controlado ao RDS via bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres interno"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-rds-sg" })
}
