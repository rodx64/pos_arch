# Bootstrap do Remote State (S3 + DynamoDB)

## Passos
1) Crie os recursos de state:
```bash
cd bootstrap
terraform init
terraform apply -auto-approve -var 'bucket_name=<seu-bucket-único-global>'
```
Anote os outputs `bucket_name` e `dynamodb_table_name`.

2) Edite `live/terragrunt.hcl` e substitua:
```hcl
locals {
  aws_region   = "us-east-1"
  state_bucket = "<bucket_name>"
  lock_table   = "<dynamodb_table_name>"
}
```

3) Provisione DEV e PROD:
```bash
cd live/dev/us-east-1
terragrunt run --all init
terragrunt run --all apply

cd ../../prod/us-east-1
terragrunt run --all init
terragrunt run --all apply
```
