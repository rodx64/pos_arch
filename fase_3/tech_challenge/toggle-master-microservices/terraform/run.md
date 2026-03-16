<!-- Se a aws ainda não tiver a key-pair -->

aws ec2 create-key-pair \
  --key-name iac-key \
  --query 'KeyMaterial' \
  --output text > iac-key.pem

chmod 400 iac-key.pem


<!-- Se o destroy falhar, mesmo usando o force_delete no ecr -->
aws ecr batch-delete-image \
  --repository-name toggle-master \
  --image-ids "$(aws ecr list-images \
    --repository-name toggle-master \
    --query 'imageIds[*]' \
    --output json)"

<!-- Atualizando kubectl local -->
aws eks update-kubeconfig --region us-east-1 --name toggle-master-eks

CLUSTER_NAME=$(kubectl config get-clusters | grep eks | tail -1)
kubectl config set-cluster $CLUSTER_NAME \
  --server=https://127.0.0.1:6443 \
  --insecure-skip-tls-verify=true
