# FinOps

## Tagging Obrigatório (IaC)

Todos os recursos AWS criados via Terraform recebem automaticamente, via `default_tags` no [provider AWS][provider-tf], as seguintes tags obrigatórias:

| Tag | Valor |
|---|---|
| `Project` | `SolidaryTech` |
| `Environment` | `Dev` / `Hom` / `Pro` |
| `CostCenter` | `NGO-Core` |
| `ManagedBy` | `Terraform` |

Para que essas tags virem relatório de custo real no Cost Explorer, é necessário um passo manual único: ativar `Project`, `Environment` e `CostCenter` como **Cost Allocation Tags** no AWS Billing Console (leva até 24h para refletir nos dados). Em contas AWS Academy, o acesso ao Billing/Cost Explorer costuma ser bloqueado para a sessão de estudante — nesse caso, o forecast manual (próxima seção) é a fonte de verdade.

> **Exceção documentada:** recursos criados via `aws_autoscaling_group` não herdam `default_tags` automaticamente — é necessário declarar as tags explicitamente no bloco `tag {}` do recurso, conforme [documentação oficial da AWS][asg-tagging].

## Rightsizing

Os 3 microsserviços partiram de `requests`/`limits` idênticos, independente da stack — Go sobre-provisionado, Python com Gunicorn de 4 workers sub-provisionado e em risco de OOMKill. Valores diferenciados por workload, validados com carga gerada pelo `k6-load-test.yaml`:

| Serviço | requests.cpu | requests.memory | limits.cpu | limits.memory |
|---|---|---|---|---|
| `donation-service` | 100m | 80Mi | 300m | 150Mi |
| `ngo-service` | 150m | 200Mi | 400m | 350Mi |
| `volunteer-service` | 120m | 180Mi | 350m | 300Mi |

**Gunicorn reduzido de `-w 4` para `-w 2`:** em Kubernetes, o padrão é escalar horizontalmente (mais réplicas via HPA/KEDA), não verticalmente (mais workers por pod). Com 4 workers competindo por meio vCPU, o ganho de paralelismo é anulado por context switching; com 2 workers, cada processo tem mais recursos e o autoscaler absorve os picos.

**Impacto agregado (3 réplicas/serviço, pior caso todos no limite):**

| | CPU total (limits) | Memória total (limits) |
|---|---|---|
| **Antes** (uniforme 500m/256Mi) | 3 × 3 × 500m = **4.500m** | 3 × 3 × 256Mi = **2.304Mi** |
| **Depois** (diferenciado) | (300+400+350) × 3 = **3.150m** | (150+350+300) × 3 = **2.400Mi** |

CPU reservável no pior caso cai **~30%**; memória sobe ligeiramente (~4%), deliberadamente, para eliminar risco de OOMKill nos serviços Python.

## Scaling

- **`donation-service`**: **KEDA** escalando por tráfego HTTP (Prometheus) com CPU como rede de segurança. `minReplicaCount: 1`, `maxReplicaCount: 4`. HPA nativo removido.
- **`ngo-service` / `volunteer-service`**: HPA nativo, CPU `averageUtilization: 70%`, `maxReplicas: 3`.
- **Scaling por fila SQS**: não implementado — a `donation-queue` só tem produtor hoje (sem consumidor no código), então não há profundidade de fila com relação causal para escalar contra.

## Forecast de Custos

| Ambiente | Estratégia | Custo estimado |
|---|---|---|
| **DEV** | Local-First (LocalStack + Docker Compose) — custo zero na AWS | **$0/mês** |
| **HOM** | Infra efêmera por janela de homologação (~20h/mês via `terragrunt apply`/`destroy`), 100% Spot | **~$9/mês** |
| **PRO** | Always-on, arquitetura mista On-Demand + Spot, Savings Plans 1 ano | **~$237/mês** (simulado) |

**Economia DEV vs. AWS always-on:** ~$237/mês, ~$2.844/ano — o argumento mais direto de FinOps: a decisão mais barata é não provisionar o que não precisa existir ainda.

**HOM vs. always-on agendado (06h–20h):** o modelo por janela (~20h/mês) representa **~95% de economia** frente a um ambiente em horário comercial fixo (~420h/mês). Isso inclui economia no Control Plane do EKS, que é cobrado mesmo com Node Group zerado.

Os valores acima são calculados com base nas taxas públicas On-Demand da AWS para `us-east-1` (EKS $0,10/h, `t3.medium` Spot ~$0,0125/h, `db.t4g.micro` $0,016/h, NAT Gateway $0,045/h) aplicadas sobre as 32h de janela. Detalhamento completo por componente, metodologia e premissas em [`3_FORECAST.md`][forecast].

## Recomendação de Otimização Nativa

**AWS Cost Anomaly Detection** segmentado por `CostCenter=NGO-Core`, com alertas via SNS/e-mail em caso de desvio do padrão histórico de gasto. Essencial no modelo de HOM por janela: qualquer cobrança fora dos períodos de homologação (ex: um `destroy` que falhou silenciosamente) é sinalizada rapidamente, sem depender de revisão manual diária de billing.

[provider-tf]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/solidary-tech/terraform/modules/root/provider.tf
[forecast]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/doc/3_FORECAST.md
[asg-tagging]: https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html
