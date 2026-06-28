resource "datadog_service_level_objective" "availability_slo" {
  for_each = var.slo_services

  name        = "[${upper(var.env)}] ${each.key}-service - Disponibilidade Geral"
  type        = "metric"
  description = "SLO gerenciado via Terraform para o serviço ${each.key}"

  query {
    numerator   = "sum:solidary_tech.http_request_duration_seconds.count{env:${var.env},service:${each.key}-service,!status:5xx}.as_count()"
    denominator = "sum:solidary_tech.http_request_duration_seconds.count{env:${var.env},service:${each.key}-service}.as_count()"
  }

  thresholds {
    timeframe = "7d"
    target    = each.value.slo_target
    warning   = each.value.slo_warning
  }

  tags = ["env:${var.env}", "service:${each.key}-service", "tier:slo"]
}

resource "datadog_monitor" "latency" {
  for_each = var.slo_services

  name = "[${upper(var.env)}][P2] SLO Performance: Latência P${each.value.latency_percentile} Degradada no ${each.key}-service"
  type = "query alert"

  query = "avg(last_5m):p${each.value.latency_percentile}:solidary_tech.http_request_duration_seconds{env:${var.env},service:${each.key}-service} > ${each.value.latency_threshold}"

  message = <<EOT
  A latência P${each.value.latency_percentile} do *${each.key}-service* ultrapassou o limiar crítico de ${each.value.latency_threshold}s.
  Verifique os traces no Datadog APM filtrando por `service:${each.key}-service`.
  
  @pagerduty-SolidaryTech
  EOT

  monitor_thresholds {
    critical = each.value.latency_threshold
    warning  = each.value.latency_threshold * 0.8
  }

  include_tags = true
  tags         = ["env:${var.env}", "service:${each.key}-service", "metric:latency"]
}

resource "datadog_monitor" "slo_burn_rate_alert" {
  for_each = var.slo_services

  name = "[${upper(var.env)}][SRE] Consumo Crítico de Error Budget: ${each.key}-service"
  type = "slo alert"

  query = "burn_rate(\"${datadog_service_level_objective.availability_slo[each.key].id}\").over(\"7d\").long_window(\"1h\").short_window(\"5m\") > 14.4"

  message = <<EOT
  Atenção! O serviço *${each.key}-service* está consumindo seu Error Budget de forma acelerada (Burn Rate > 14.4x).
  Se a taxa de erros atual se mantiver, o SLO de Disponibilidade mensal será violado.
  
  Inicie a triagem imediatamente verificando os traces no APM e os logs associados a erros 5xx.
  
  @pagerduty-SolidaryTech
  EOT

  monitor_thresholds {
    critical = 14.4
  }
}

resource "datadog_service_level_objective" "business_journey_donation_slo" {
  name        = "[${upper(var.env)}] Jornada de Negócio - Efetuar Doação end-to-end"
  type        = "metric"
  description = "Acompanha o sucesso real do doador monitorando o Trace Raiz da transação através de múltiplos microsserviços."

  query {
    numerator   = "sum:trace.http.request.hits{env:${var.env},service:donation-service,resource:post_v1_donations,!errors}.as_count()"
    denominator = "sum:trace.http.request.hits{env:${var.env},service:donation-service,resource:post_v1_donations}.as_count()"
  }

  thresholds {
    timeframe = "30d"
    target    = 99.0
  }

  tags = ["env:${var.env}", "type:business-journey", "tier:core-cuj"]
}

resource "datadog_monitor" "watchdog_traffic_anomaly" {
  name = "[${upper(var.env)}][AIOps] Anomalia de Tráfego — donation-service"
  type = "query alert"

  query = "avg(last_4h):anomalies(sum:solidary_tech.http_request_duration_seconds{env:${var.env},service:donation-service}.as_count(), 'basic', 2, direction='both', alert_window='last_5m', interval=60, count_default_zero='true') >= 1"

  message = <<EOT
  O Watchdog identificou um padrão de tráfego fora do comportamento histórico esperado no *donation-service*
  (queda ou pico abrupto de doações). Verifique o Watchdog Insights no APM antes de escalar como incidente.

  @pagerduty-SolidaryTech
  EOT

  monitor_thresholds {
    critical = 1
  }

  tags = ["env:${var.env}", "type:aiops-anomaly", "service:donation-service"]
}
