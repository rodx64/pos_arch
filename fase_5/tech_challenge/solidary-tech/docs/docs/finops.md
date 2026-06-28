# FinOps

> Relatórios completos de [Forecast][1] e [Right Sizing][2] para o projeto.

## Tagging obrigatório (IaC)

Todos os recursos AWS criados via Terraform recebem automaticamente, via `default_tags` no [provider][3]:

Para que essas tags virem relatório de custo real (Cost Explorer), é necessário um passo manual único: ativar `Project`, `Environment` e `CostCenter` como **Cost Allocation Tags** no AWS Billing Console (leva até 24h para refletir nos dados). Em contas AWS Academy (nosso caso), o acesso ao Billing/Cost Explorer costuma ser bloqueado para a sessão de estudante — nesse caso, o forecast manual (próxima seção) é a fonte de verdade.

## Rightsizing

Os 3 microsserviços partiram de `requests`/`limits` **idênticos**, independente da stack — um anti-padrão clássico (Go sobre-provisionado, Python com Gunicorn de 4 workers sub-provisionado e em risco de OOM). Valores diferenciados por workload, com Gunicorn reduzido de `-w 4` para `-w 2` (escalar horizontalmente via autoscaler, não verticalmente com mais processos por pod):

Resultado: ~30% menos CPU reservável no pior caso (3 réplicas/serviço), com memória ajustada para eliminar risco real de OOMKill nos serviços Python.

Esse rightsizing caminha junto com a estratégia de scaling: `donation-service` migrou de HPA por CPU para **KEDA** (tráfego HTTP via Prometheus + CPU como rede de segurança); `ngo`/`volunteer` continuam em HPA nativo. Detalhes completos, incluindo por que scaling por fila SQS não foi adotado (sem consumidor hoje), em `4_RIGHTSIZING.md`.

## Forecast de custos

- **DEV** roda 100% local (LocalStack + Kind/Docker Compose) — custo zero, economia estimada de ~$237/mês em relação a rodar a mesma topologia na AWS.
- **HOM** é provisionado **por janela de homologação** (Terragrunt apply/destroy sob demanda, ~32h/mês), não 24/7 — economia de ~95% frente a um modelo agendado fixo.
- **PRO** (ainda não provisionado) é o único ambiente *always-on*, com recomendações de Savings Plans e RDS Reserved Instances.

Recomendação prática de otimização nativa: **AWS Cost Anomaly Detection**, segmentado por `CostCenter=NGO-Core`, para alertar desvios de gasto sem depender de revisão manual diária de billing.

[1]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/doc/3_FORECAST.md
[2]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/doc/4_RIGHTSIZING.md
[3]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/solidary-tech/terraform/modules/root/provider.tf
