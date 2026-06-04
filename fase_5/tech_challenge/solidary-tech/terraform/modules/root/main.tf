module "vpc" {
  source          = "../vpc"
  project_name    = "solidary-tech"
  env             = var.env
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
}


module "s3" {
  source       = "../s3"
  project_name = "solidary-tech"
  env          = var.env
}


module "ecr" {
  source = "../ecr"

  project_name = "solidary-tech"
  env          = var.env
  repositories = var.ecr_repositories
  tag_prefixes = length(var.ecr_tag_prefixes) > 0 ? var.ecr_tag_prefixes : var.ecr_repositories
  force_delete = var.force_delete
}


module "ec2" {
  source        = "../ec2"
  project_name  = "solidary-tech"
  env           = var.env
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = module.vpc.public_subnet_ids[0]
  vpc_id        = module.vpc.vpc_id
}


module "eks" {
  source             = "../eks"
  project_name       = "solidary-tech"
  count              = var.enable_eks ? 1 : 0
  kubernetes_version = var.kubernetes_version
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  bastion_sg_id      = module.ec2.bastion_sg_id
}


module "rds" {
  source       = "../rds"
  project_name = "solidary-tech"
  env          = var.env
  for_each     = var.databases

  app_owner_name = each.value.app_owner_name
  identifier     = each.key
  db_name        = each.value.db_name
  db_user        = each.value.db_user

  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
}


module "dynamodb" {
  source   = "../dynamodb"
  for_each = var.dynamodb_tables

  project_name  = "solidary-tech"
  env           = var.env
  table_name    = each.value.table_name
  hash_key      = each.value.hash_key
  hash_key_type = lookup(each.value, "hash_key_type", "S")
}


module "sqs" {
  source   = "../sqs"
  for_each = var.sqs_queues

  project_name               = "solidary-tech"
  env                        = var.env
  queue_name                 = each.value.queue_name
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  create_dlq                 = each.value.create_dlq
  max_receive_count          = each.value.max_receive_count
}
