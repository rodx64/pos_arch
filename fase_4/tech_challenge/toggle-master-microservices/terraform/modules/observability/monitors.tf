resource "datadog_monitor" "targeting_auth_dependency_error" {
  name = "[P2] Falha de Dependência: Targeting recebendo 503 do Auth Service"
  type = "query alert"

  query = "sum(last_5m):sum:calls{env:dev,service:targeting-service,http.status_code:503}.as_rate() / sum:calls{env:dev,service:targeting-service}.as_rate() > 0.1"

  message = <<EOT
  {{#is_alert}}
  O serviço *targeting-service* está com uma taxa de erros HTTP 503 superior a 10% nos últimos 5 minutos.
  
  *Contexto do Alerta:*
  Geralmente, isso ocorre quando o `targeting-service` tenta autenticar e o **`auth-service` está desligado ou inacessível**.
  
  *Detalhes do Incidente:*
  - Ambiente: {{env.name}}
  - Status Code: 503 (Service Unavailable)
  - Taxa de erro atual: {{value}}%
  
  *Ações Recomendadas (Runbook):*
  1. Verifique imediatamente a saúde do `auth-service` (Kubelet / Pods).
  2. Caso o `auth-service` esteja em CrashLoop, verifique os logs dele.
  
  @pagerduty-ToggleMaster
  {{/is_alert}}
  
  {{#is_recovery}}
  A taxa de erros 503 no targeting-service normalizou para abaixo de 10%. A comunicação com o auth-service parece ter sido reestabelecida.
  
  @pagerduty-ToggleMaster
  {{/is_recovery}}
  EOT

  monitor_thresholds {
    critical = 0.10
    warning  = 0.05
  }

  include_tags = true
  tags         = ["service:targeting-service", "env:dev", "dependency:auth-service", "team:backend"]
}
