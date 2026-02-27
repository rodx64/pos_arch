variable "name" {
  description = "Nome base da VPC"
  type        = string
}

variable "cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
}

variable "enable_nat" {
  description = "Criar NAT Gateway"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags padrão"
  type        = map(string)
  default     = {}
}
