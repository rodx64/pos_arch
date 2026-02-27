variable "cluster_name"   { type = string }
variable "vpc_id"         { type = string }
variable "subnet_ids"     { type = list(string) } # Subnets onde os nós vão rodar (públicas para simplificar)
variable "common_tags"    { type = map(string), default = {} }
variable "k8s_version"    { type = string, default = "1.29" }
variable "instance_types" { type = list(string), default = ["t3.small"] }
variable "desired_size"   { type = number, default = 2 }
variable "min_size"       { type = number, default = 1 }
variable "max_size"       { type = number, default = 3 }
variable "capacity_type"  { type = string, default = "ON_DEMAND" } # ou "SPOT"
