# Requisitos técnicos

## 1. Monitoramento Opensource (Métricas e Logs no K8s)
Provisione as ferramentas base de observabilidade dentro do seu cluster
Kubernetes

- [x] `Prometheus`: para armazenamento e consulta de métricas de infraestrutura.
- [x] `Loki`: para centralização e indexação de todos os logs dos contêineres do cluster
- [x] `Grafana`: como ferramenta principal de visualização
    - [x] 1 Dashboard customizado que centralize a saúde do sistema

## 2. OpenTelemetry (OTel) e Padronização
O monitoramento moderno exige padronização.

- [x] `OTel Collector` ou `Grafana Alloy` 
Utilize o OpenTelemetry (via OTel Collector) como a peça central para receber, processar e exportar suas métricas, logs e traces. Os microsserviços devem enviar os dados de telemetria para o OTel, e ele se encarregará de roteá-los para os backends corretos (Prometheus, Loki e APM).

## 3. Instrumentação e APM (Traces e Visibilidade Profunda)

- [x] `Ferramenta APM:` Escolher entre Datadog ou New Relic
- [x] `Instrumentação do Código`: Altere o código-fonte ou o Dockerfile dos microsserviços para adicionar as bibliotecas de instrumentação
- [x] `Distributed Tracing`: Ao fazer uma
requisição no evaluation-service, o APM deve mostrar o "caminho" da requisição
- [ ] `Service Map`: o painel do APM deve exibir o mapa de dependências
dos seus 5 microsserviços

## 4. Alertas Inteligentes e Self-Healing

- [ ] `Criação do Alerta`: configure um alerta inteligente (no Grafana ou
APM)
- [ ] `Gerenciamento de Incidentes`: crie uma conta no PagerDuty OU
OpsGenie e integre o alerta para abrir um incidente automaticamente.
- [ ] `Notificação (ChatOps)`: configure o envio de uma notificação
detalhada para um canal do Slack, Discord ou Teams.
- [ ] `Self-Healing`: crie uma automação (Runbook Automation, AWS Lambda, ou GitHub Action disparada via webhook) que reaja automaticamente ao alerta criado

