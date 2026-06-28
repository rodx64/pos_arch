# CI/CD e Infraestrutura

A automação é baseada em GitHub Actions e Terraform/Terragrunt.

- **Infraestrutura**: Pipelines automáticos em [infra][1] gerenciam o ciclo de vida dos recursos via Terragrunt.
- **Serviços**: Cada serviço ([donation][2], [ngo][3], [volunteer][4]) possui sua própria esteira de build/push para ECR e atualização de imagem no cluster.
- **Deploy**: Utilizamos ArgoCD para realizar o deploy contínuo das aplicações no EKS.

[1]: https://github.com/rodx64/pos_arch/blob/develop/.github/workflows/ci-infra.yml
[2]: https://github.com/rodx64/pos_arch/blob/develop/.github/workflows/ci-donation.yml
[3]: https://github.com/rodx64/pos_arch/blob/develop/.github/workflows/ci-ngo.yml
[4]: https://github.com/rodx64/pos_arch/blob/develop/.github/workflows/ci-volunteer.yml
