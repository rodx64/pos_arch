# outputs.tf
# Retorna ID da VPC principal
output "vpc_id" {
  value = module.network.vpc_id
}

# Retorna IDs das subnets criadas
output "subnet_ids" {
  value = module.network.subnet_ids
}

# Retorna IDs das instâncias web criadas com count
output "web_instances" {
  value = aws_instance.web[*].id
}

# Retorna IDs das instâncias criadas com for_each
output "apps_instances" {
  value = { for k, inst in aws_instance.apps : k => inst.id }
}

# Retorna o ID do Security Group criado com dynamic block
output "security_group_id" {
  value = aws_security_group.web_sg.id
}

# Retorna o ID da VPC pública criada via módulo do Registry
output "public_vpc_id" {
  value = module.public_vpc.vpc_id
}
