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
