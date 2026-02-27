# ===================================
# terraform.tfvars - Valores padrão
# ===================================
environment_name = "dev"
ami_id           = "ami-0360c520857e3138f"
instance_type    = "t2.micro"
ssh_access_cidr  = "0.0.0.0/0"

# IDs da VPC e Subnet (pre-existentes)
vpc_id    = "vpc-09dabb72414674da8"
subnet_id = "subnet-0e00ce0cb488df91f"
