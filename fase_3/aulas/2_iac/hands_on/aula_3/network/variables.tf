# modules/network/variables.tf
# Variável para definir o bloco CIDR da VPC
variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

# Variável que define as subnets em formato de mapa (zona -> CIDR)
variable "subnets" {
  description = "Mapa de zonas de disponibilidade e seus CIDRs"
  type        = map(string)
}
