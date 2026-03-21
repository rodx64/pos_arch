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

<!-- Pega o external IP/hostname do LoadBalancer -->
kubectl get svc argocd-server -n argocd

<!-- usuário: admin -->
<!-- senha: -->
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
