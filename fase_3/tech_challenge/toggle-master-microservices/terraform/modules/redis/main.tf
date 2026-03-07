resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.cluster_id}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name    = "${var.cluster_id}-subnet-group"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.env}-${var.cluster_id}-sg"
  description = "Security group for Redis ${var.cluster_id}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-${var.cluster_id}-sg"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  engine_version       = var.engine_version
  port                 = var.port
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.this.id]

  tags = {
    Name    = var.cluster_id
    Project = var.project_name
    Env     = var.env
  }
}
