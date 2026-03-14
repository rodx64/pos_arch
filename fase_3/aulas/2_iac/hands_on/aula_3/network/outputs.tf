# modules/network/outputs.tf
# Retorna o ID da VPC criada
output "vpc_id" {
  value = aws_vpc.main.id
}

# Retorna uma lista com todos os IDs das subnets
output "subnet_ids" {
  value = values(aws_subnet.subnets)[*].id
}
