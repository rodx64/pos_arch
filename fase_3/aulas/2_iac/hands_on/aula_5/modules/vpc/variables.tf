variable "name"            { type = string }
variable "cidr_block"      { type = string }
variable "azs"             { type = list(string) } # Ex.: ["us-east-1a","us-east-1b"]
variable "common_tags"     { type = map(string), default = {} }
variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para subnets públicas (mesmo tamanho de azs)"
  type        = list(string)
  default     = []
}
