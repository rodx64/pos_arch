# ==============================
# outputs.tf - Saída de valores
# ==============================

# ID da instância EC2 criada
output "instance_id" {
  value       = aws_instance.example.id
  description = "ID da instância criada"
}

# VPC usada para os recursos
output "vpc_id" {
  value       = var.vpc_id
  description = "VPC usada para os recursos"
}

# Subnet usada para os recursos
output "subnet_id" {
  value       = var.subnet_id
  description = "Subnet usada para os recursos"
}
