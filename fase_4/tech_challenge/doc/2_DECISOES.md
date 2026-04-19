# Decisões

## Coleta

### Estratégia central para eliminar coleta duplicada: 

Prometheus coleta, Datadog consome. O Datadog Agent para de fazer scrape de métricas e passa a receber via remote_write do Prometeus, eliminando a coleta duplicada.

```
Microserviços → Prometheus (scrape único)
                     └── remote_write → Datadog/New Relic
                     └── Grafana
```

#### - Prometeus
```yaml
remote_write:
  - url: https://api.datadoghq.com/api/v1/series
    bearer_token: ${DATADOG_API_KEY}

    # Crítico: filtrar só o que o Datadog precisa ver
    write_relabel_configs:
      - source_labels: [__name__]
        regex: "http_requests_total|cpu_usage|memory_usage|error_rate"
        action: keep
```

#### - Datadog
```yaml
datadog:
  prometheusScrape:
    enabled: false    # Prometheus já faz isso

  logs:
    enabled: true     # Datadog cuida de logs
  
  apm:
    enabled: true     # Datadog cuida de APM/tracing
```

