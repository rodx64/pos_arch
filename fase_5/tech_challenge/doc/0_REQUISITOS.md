Requisitos técnicos

Sua entrega será avaliada em 5 frentes de requisitos.

0. A Fundação DevOps (Fases 1 a 4) - Requisito Obrigatório

Antes de aplicar as práticas da Fase 5, seu projeto deve comprovar a
utilização de todas as disciplinas anteriores:

- [x] Docker e Kubernetes: criação de Dockerfiles otimizados para os 3
    novos serviços e implantação no Kubernetes (EKS, AKS ou GKE).
- [x] Infraestrutura como Código (IaC): provisionamento de todo o
    ambiente (Cluster, Bancos de Dados, Mensageria, Rede) via
    Terraform.
- [x] CI/CD e DevSecOps: pipelines automatizados (ex: GitHub Actions)
    contemplando testes, scans de segurança (SAST/SCA com
    ferramentas como Trivy/Sonar) e construção da imagem.
- [x] GitOps: entrega contínua configurada através de ferramentas como
    ArgoCD ou FluxCD.
- [x] Observabilidade e APM: stack completa rodando (Prometheus,
    Grafana, Loki e/ou OpenTelemetry) e instrumentação dos códigos no
    APM (Datadog ou New Relic) com Distributed Tracing.

1. SRE: Confiabilidade e Golden Metrics

A engenharia de confiabilidade deve ser a prioridade.

- [x] Definição de SLOs e SLIs: para o donation-service, defina e
    documente, no mínimo, dois SLIs (Service Level Indicators) baseados
    nas Golden Metrics (ex: Latência e Taxa de Erros). Estabeleça o SLO
    (Service Level Objective) para cada um (ex: 99.9% de sucesso).
- [x] Dashboard SRE: crie um painel específico no Grafana ou na
    ferramenta de APM focado exclusivamente nos SLOs e no consumo
    do Error Budget da plataforma.
- [x] MTTR: evidencie no relatório como a stack de observabilidade e as
    automações de resposta a incidentes ajudam a reduzir ativamente o
    MTTR (Mean Time To Recovery).

2. FinOps: Otimização Financeira e Tagueamento

Como o orçamento da ONG é limitado, cada centavo conta.

- [x] Estratégia de Tagging (IaC): implemente uma política de tags
    rigorosa diretamente no seu código Terraform. Todos os recursos de
    nuvem devem conter tags obrigatórias como Project=SolidaryTech,
    Environment=Production e CostCenter=NGO-Core.
- [x] Rightsizing: analise as métricas de CPU/Memória do Kubernetes e
    ajuste os requests e limits dos Pods nos manifestos YAML (via GitOps)
    para evitar desperdício de recursos.
- [x] Relatório de Forecast: crie uma projeção (Forecast) de custos
    mensais da arquitetura. Indique pelo menos uma recomendação
    prática de otimização nativa de nuvem.

3. ITSM e AIOps: Gestão Preditiva

Incidentes devem ser previstos antes de afetarem o doador.

- [x] Configuração de AIOps: ative as funcionalidades de Inteligência
    Artificial da sua ferramenta de APM (ex: Watchdog no Datadog ou
    Applied Intelligence no New Relic) para detectar anomalias
    comportamentais automáticas.
- [x] Gestão de Incidentes (ITSM): desenhe o fluxo de vida de um
    incidente da SolidaryTech (da detecção via AIOps/Alerta até o Post-
    Mortem e comunicação aos stakeholders).

4. Multicloud, Segurança e Disaster Recovery (DR)

Se o cluster principal cair, a SolidaryTech precisa sobreviver.

- [ ] Plano de Continuidade de Negócios (PCN): escreva um documento
    executivo de PCN. Defina os valores críticos de RTO (Recovery Time
    Objective) e RPO (Recovery Point Objective) para os dados das
    doações.
- [ ] Estratégia de DR Prática: Implemente e evidencie uma estratégia de
    backup/DR.
    o Opção A (Multicloud/Cross-Region Backup): configure o Velero no
       Kubernetes para fazer backup do estado do cluster (manifestos e
       volumes) para um bucket externo.
    o Opção B (Infraestrutura Ativo-Passivo): utilize seu Terraform para
       modularizar a infraestrutura e ser capaz de levantar um ambiente
       "espelho" (Warm Standby) em outra região com 1 comando.
