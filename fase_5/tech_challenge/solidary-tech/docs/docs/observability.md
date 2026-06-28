# Observabilidade e AIOps

Stack híbrida, alimentada por uma única instrumentação (OpenTelemetry) nos 3 serviços:


- **Coleta:** `otel-collector` (DaemonSet, namespace `monitoring`) recebe traces/métricas/logs via OTLP gRPC/HTTP e `filelog`, processa (`k8sattributes`, `transform` para `operation.name`) e exporta para dois destinos em paralelo.
- **Open-source:** **Prometheus** (métricas, `prometheusremotewrite`), **Loki** (logs) e **Grafana** (dashboards — painel "Solidary Tech — Saúde do Ecossistema", com CPU/memória por pod, taxa de requisições, latência P99, doações criadas e status dos componentes).
- **APM/SaaS:** **Datadog** (traces, métricas, logs, dashboards de SRE e AIOps).

## Métricas customizadas

Cada serviço expõe `/metrics` (Prometheus format): `http_requests_total`, `http_request_duration_seconds`, `db_up`, e `donations_created_total` (específico do `donation-service`, golden metric de negócio).

## AIOps

O **Datadog Watchdog** monitora anomalias comportamentais automaticamente, sem configuração manual, a partir do mesmo fluxo de traces/métricas já descrito acima (ex: anomalias em `solidary_tech.http_request_duration_seconds`). Um monitor de anomalia explícito (`anomalies()`) complementa a varredura autônoma, formalizado via Terraform. Detalhes completos em [AIOps e Gestão de Incidentes](./itsm-aiops.md).

## SLOs

Definidos para a jornada crítica de doação (taxa de sucesso, latência e jornada end-to-end), garantindo a qualidade do serviço do `donation-service`. Detalhes completos em [SRE e Confiabilidade](./sre.md).

--- 
Diretórios relevantes do Github: [EKS observability][1], [Módulo terraform para observability][2]

[1]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/eks/observability
[2]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/terraform/modules/observability
