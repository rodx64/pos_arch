variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "instance_types" {
  type    = list(string)
  default = ["t2.micro"]
}

variable "bastion_sg_id" {
  type        = string
  description = "Security Group ID do bastion para acesso ao EKS"
}
