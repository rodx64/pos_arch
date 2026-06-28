variable "env" {
  type        = string
  description = "Ambiente (dev/hom/pro). Usado para tags FinOps explícitas no Node Group, já que o ASG criado pelo EKS não herda default_tags do provider de forma garantida."
}

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
  default = ["t3.medium"]
}

variable "bastion_sg_id" {
  type        = string
  description = "Security Group ID do bastion para acesso ao EKS"
}
