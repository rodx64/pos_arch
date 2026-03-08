<!-- Se a aws ainda não tiver a key-pair -->

aws ec2 create-key-pair \
  --key-name iac-key \
  --query 'KeyMaterial' \
  --output text > iac-key.pem

chmod 400 iac-key.pem


Como executar:

1. Entrar na pasta backend e executar o terraform
cd /backend
```
terraform init 
terraform plan 
terraform apply
```

após o apply

/modules
terragrunt init --all
terragrunt apply --all

<!-- Se o destroy falhar, mesmo usando o force_delete no ecr -->
aws ecr batch-delete-image \
  --repository-name toggle-master \
  --image-ids "$(aws ecr list-images \
    --repository-name toggle-master \
    --query 'imageIds[*]' \
    --output json)"
