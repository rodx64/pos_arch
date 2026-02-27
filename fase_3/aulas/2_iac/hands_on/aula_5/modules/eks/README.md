# EKS Module
Cria um **cluster EKS real** com:
- IAM Role para o control plane (AmazonEKSClusterPolicy, AmazonEKSServicePolicy)
- Cluster EKS (`aws_eks_cluster`)
- IAM Role para nós + políticas (WorkerNode, CNI, ECR ReadOnly)
- Node Group gerenciado (`aws_eks_node_group`)

Entradas: `cluster_name`, `subnet_ids`, `vpc_id`, `instance_types`, `desired_size` etc.
