# outputs.tf
# Expondo informações da infraestrutura criada

output "instance_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "ID da instância EC2 criada"
  value       = aws_instance.web.id
}

output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID da Subnet criada"
  value       = aws_subnet.subnet.id
}
