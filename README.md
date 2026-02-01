# ☁️ Pós-Graduação em Arquitetura Cloud

![Cloud Architecture](https://images.unsplash.com/photo-1504639725590-34d0984388bd?q=80\&w=1600\&auto=format\&fit=crop)

> Repositório dedicado às **entregas dos Tech Challenges** da **Pós-Graduação em Arquitetura Cloud**, organizado em **5 fases progressivas**, com foco em arquitetura, boas práticas, escalabilidade, segurança e governança em nuvem.

---

## 🏷️ Tags

`#cloud-computing` `#cloud-architecture` `#aws` `#azure` `#gcp` `#devsecops` `#terraform` `#kubernetes` `#microservices` `#security` `#finops` `#observability`

---

## 📌 Visão Geral

Este repositório centraliza todas as entregas práticas (Tech Challenges) desenvolvidas ao longo da pós. Cada fase representa um nível de maturidade maior em **Arquitetura Cloud**, indo desde fundamentos até soluções corporativas completas.

📚 **Objetivos principais:**

* Aplicar conceitos teóricos em cenários reais
* Projetar arquiteturas cloud escaláveis e seguras
* Utilizar ferramentas modernas do ecossistema cloud
* Documentar decisões arquiteturais (ADRs)

---

## 🧭 Fases

```text
📦 tech-challenges
 ┣ 📂 fase-01-arquitetura-cloud
 ┣ 📂 fase-02-escalabilidade-e-conteinerização
 ┣ 📂 fase-03-pipelines-e-seguranca
 ┣ 📂 fase-04-observabilidade-e-monitoramento
 ┣ 📂 fase-05-multicloud-e-segurança
```

---

## 🚀 Fases do Tech Challenge

### 🟢 Fase 01 — CULTURA DEVOPS E ARQUITETURA CLOUD

![Fundamentos](https://img.shields.io/badge/Fase-01-success?style=for-the-badge)

📌 **Conteúdo:**

- [x] Cultura DevOps e colaboração
    - [x] Compreensão da Cultura DevOps.
    - [x] Implemente pipelines de ponta a ponta com CI/CD.
    - [x] Acelere a entrega de software com automação e colaboração.
    - [x] Conheça as principais ferramentas.
- [x] Arquitetura Cloud
    - [x] Arquiteturas Cloud otimizadas para AWS, Azure e GCP.
    - [x] Modelos de serviços com IaaS, PaaS, SaaS e FaaS.
    - [x] Crie soluções seguras, com custos controlados na nuvem.
    - [x] Redes privadas, públicas e híbridas, AZs, Edge Locations e Regiões.
- [x] Arquitetura de Aplicações
    - [x] Do monolito ao microsserviço.
    - [x] Arquitetura distribuída e em camadas.
    - [x] Padrões de comunicação e banco de dados
- [x] AWS
    - [x] Domine a infraestrutura e orquestração da AWS: VPC, EC2, ECS, EKS, ELB.
    - [x] Gerencie bancos de dados de alta performance (Aurora, RDS, DynamoDB).
    - [x] Garanta segurança com Secrets, WAF e IAM.
    - [x] AWS Academy e Certificações.

📁 Pasta: `fase_1`

---

### 🔵 Fase 02 — ESCALABILIDADE E CONTEINERIZAÇÃO

![Arquitetura](https://img.shields.io/badge/Fase-02-blue?style=for-the-badge)

📌 **Conteúdo:**

- [x] Introdução a Containers
    - [x] Containers e arquitetura linux.
    - [x] Dockerfile, imagens, volumes e registries.
    - [x] Aplicações compostas com Docker compose.
    - [x] Segurança e boas práticas com Docker
- [x] Kubernetes Básico
    - [x] Arquitetura do Kubernetes (k8s).
    - [x] Cluster com Kind, Minikube e Cloud.
    - [x] Control Plane, Worker Nodes e API.
    - [x] Deployments, Pods, Services, ConfigMaps e Secrets, PV e PVC, HPA e VPA.
- [x] Kubernetes Avançado
    - [x] Gerenciador de pacotes com Helm Charts.
    - [x] Escalabilidade com Karpenter e KEDA.
    - [x] Estratégias de deploy com Blue/Green e Canary.
    - [x] Segurança com RBAC, Service Accounts e Cert-Manager.
    - [x] Liveness, Readiness, Limits e Resources.
    - [x] Taints, Tolerations, Evictions e Rollout.
- [x] Escalabilidade de Servidores
    - [x] Fundamentos de Escalabilidade Moderna.
    - [x] Load Balancers, CDNs e Performance Global.
    - [x] Padrões de escala horizontal e vertical.
    - [x] Escalabilidade de banco de dados.
- [x] Servidores Web e Balanceamento de Carga
    - [x] Domine Web Servers com Nginx, Apache e IIS.
    - [x] Balanceamento de Carga com Web Servers e Containers.
    - [x] Proxy, Proxy Reverso e Alta Disponibilidade

📁 Pasta: `fase_02`

---

### 🟣 Fase 03 — PIPELINES E SEGURANÇA NA CLOUD

![DevOps](https://img.shields.io/badge/Fase-03-purple?style=for-the-badge)

📌 **Conteúdo:**

- [ ] CI / CD
    - [x] Criação de pipelines Eficientes com Github Actions.
    - [x] Multistage, Paralelismo e Condições Avançadas.
    - [ ] Ambientes, Secrets e Multi-Tenant.
    - [ ] Notificações, Alertas e Observabilidade no CI/CD.
    - [ ] Deploy Automatizado em Kubernetes na Nuvem
- [ ] IAAC
    - [ ] Terraform, Cloud, OpenTofu e Terragrunt.
    - [ ] Automação com IaC e CI/CD.
    - [ ] Módulos, Loops e conditions.
    - [ ] Kubernetes via Terraform: Usando o Provider Kubectl.
    - [ ] Auditoria, Versionamento e Segurança em IaC.
- [ ] DevSecOps
    - [ ] DevSecOps e principais ameaças.
    - [ ] OWASP, MITRE e Defesa contra DDoS.
    - [ ] Segurança em Pipelines: SAST e DAST.
    - [ ] Detecção de Ameaças e Gestão com SIEM.
    - [ ] LGPD, Auditoria e Conformidade na Cloud.
- [ ] Segurança na Cloud
    - [ ] Principais Ameaças em Ambientes Cloud.
    - [ ] Modelo de Responsabilidade Compartilhada na Nuvem.
    - [ ] Segurança de Identidade e Acesso (IAM, MFA e Zero Trust).
    - [ ] Proteção de Dados: Criptografia e Privacidade.
    - [ ] Ferramentas de CSPM, CWPP e CASB

📁 Pasta: `fase-03`

---

### 🔴 Fase 04 — Observabilidade e Monitoramento

![Security](https://img.shields.io/badge/Fase-04-red?style=for-the-badge)

📌 **Conteúdo:**

- [ ] Observabilidade e Monitoramento
    - [ ] Fundamentos de Monitoramento e Observabilidade.
    - [ ] Os 3 pilares (Logs, Métricas e Traces).
    - [ ] Métricas de Infraestrutura, Aplicação e Containers.
    - [ ] Alertas e Notificações (Slack, Teams e Email).
- [ ] Monitoramento Open Source
    - [ ] Zabbix, Prometheus, Grafana, OpenTelemetry, Jaeger, StatsD e Loki.
    - [ ] Instalação, configuração e integração.
    - [ ] Monitoramento OpenSource no Kubernetes.
- [ ] APM
    - [ ] Métricas e Performance com Datadog, New Relic e ELK.
    - [ ] Logs, Métricas e Traces na prática.
    - [ ] Alertas Inteligentes e Automação.
    - [ ] Troubleshooting Avançado e Otimização de Performance/Custos com APM.
- [ ] Automação de Incidentes
    - [ ] Monitoramento Ativo, escalation e call rotation.
    - [ ] MTTR baixo com PagerDuty e OpsGenie.
    - [ ] Notificação com Slack, Teams, Email.
    - [ ] Automação com Functions.

📁 Pasta: `fase-04`

---

### ⚫ Fase 05 — MultiCloud e Segurança

![Advanced](https://img.shields.io/badge/Fase-05-black?style=for-the-badge)

📌 **Conteúdo:**

- [ ] Multicloud e Segurança
    - [ ] Criação e Automação Multicloud (AWS, Azure e GCP).
    - [ ] Segurança e privacidade centralizada.
    - [ ] Disaster Recovery e PCN.
    - [ ] Casos de Uso e Cenários reais
- [ ] SRE
    - [ ] SRE (Site Reliability Engineering)
    - [ ] Cultura e papel do SRE.
    - [ ] SRE vs DevOps: Diferenças e Colaborações.
    - [ ] Golden Metrics, Runbooks e Post-Mortem.
    - [ ] SLA, SLI, SLO e Error Budget.
    - [ ] MTTR, RTO e RPO
- [ ] FinOps
    - [ ] Cultura FinOps na Cloud.
    - [ ] Rightsizing, Forecast, Savings Plans, Spot Instances.
    - [ ] Tagueamento de recursos e automação de economia.
    - [ ] Visibilidade com Kubecost e AWS Cost Explorer.
- [ ] IT Service Management e AIOps
    - [ ] A Evolução do ITSM e o Papel do AIOps.
    - [ ] Boas práticas e Frameworks: ITIL e ISO/IEC 20000.
    - [ ] Ciclo de Vida e Estratégias de Serviços.
    - [ ] AIOPs no gerenciamento preditivo da TI.

📁 Pasta: `fase-05`

---

## 🛠️ Tecnologias Utilizadas

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge\&logo=amazonaws\&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge\&logo=microsoftazure\&logoColor=white)
![GCP](https://img.shields.io/badge/GCP-4285F4?style=for-the-badge\&logo=googlecloud\&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge\&logo=docker\&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge\&logo=kubernetes\&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge\&logo=terraform\&logoColor=white)

---

## 📄 Documentação

Cada fase contém:

* 📘 README específico
* 🧩 Diagramas arquiteturais

---

## ⭐ Observações Finais

Este repositório representa a evolução prática ao longo da pós-graduação.
Se este projeto te ajudou ou inspirou, não esqueça de deixar uma ⭐ no repositório!

---

☁️ "Arquitetura Cloud não é apenas tecnologia, é estratégia."
