# Helm no Kubernetes — Guia Prático e Explicado

## O que é o Helm?

**Helm** é o **gerenciador de pacotes do Kubernetes**.  
Ele permite empacotar, versionar, instalar e atualizar aplicações Kubernetes de forma **parametrizável e reutilizável**.

Se o Kubernetes usa YAML, o Helm adiciona:
- Templates
- Variáveis
- Lógica simples
- Versionamento de releases

---

## Qual problema o Helm resolve?

Em aplicações reais, você precisa:
- Reutilizar manifests Kubernetes
- Parametrizar configurações
- Instalar a mesma aplicação em vários clusters
- Fazer upgrade e rollback com segurança

❌ YAML puro:
- Muito repetitivo
- Difícil de versionar como produto
- Pouca flexibilidade

✅ Helm:
- Templates reutilizáveis
- Parâmetros por ambiente
- Controle de versão
- Rollback fácil

---

## Conceito central

> **Chart = pacote Helm**

Um **Chart** contém:
- Templates Kubernetes
- Valores padrão
- Metadados

Ele funciona como um **pacote instalável**.

---

## Estrutura de um Chart Helm

```
todo-api/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── charts/
```

---

## Chart.yaml

```yaml
apiVersion: v2
name: todo-api
description: API de exemplo
type: application
version: 0.1.0
appVersion: "1.0"
```

- `version` → versão do chart
- `appVersion` → versão da aplicação

---

## values.yaml (valores padrão)

```yaml
replicaCount: 1

image:
  repository: todo-api
  tag: latest

service:
  type: ClusterIP
  port: 80
```

📌 Esses valores podem ser sobrescritos por ambiente.

---

## Template: deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: todo-api
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

📌 Aqui está a grande diferença:
- `{{ }}` são **templates**
- Helm renderiza YAML antes de aplicar no cluster

---

## Instalando um Chart

```bash
helm install todo-api ./todo-api
```

Isso cria um **release** chamado `todo-api`.

---

## Sobrescrevendo valores por ambiente

### Arquivo values-prod.yaml

```yaml
replicaCount: 5

image:
  tag: v1.3
```

Instalação em produção:

```bash
helm install todo-api ./todo-api -f values-prod.yaml
```

---

## Upgrade e rollback

### Upgrade

```bash
helm upgrade todo-api ./todo-api -f values-prod.yaml
```

### Rollback

```bash
helm rollback todo-api 1
```

📌 Helm mantém histórico de releases.

---

## Helm vs Kustomize (comparação direta)

| Helm | Kustomize |
|----|----|
| Usa templates | Usa YAML puro |
| Parametrização poderosa | Customização declarativa |
| Ideal para distribuição | Ideal para ambientes |
| Mais complexo | Mais simples |

👉 Regra prática:
- **Aplicação como produto** → Helm
- **Aplicação interna por ambiente** → Kustomize

---

## Helm em CI/CD e GitOps

Exemplo em pipeline:

```bash
helm upgrade --install todo-api ./todo-api -f values-${ENV}.yaml
```

Ferramentas GitOps:
- ArgoCD
- FluxCD

👉 suportam Helm nativamente.

---

## Quando NÃO usar Helm

❌ Templates complexos demais  
❌ Lógica difícil de entender  
❌ Quando YAML puro resolve  

Nesses casos, Kustomize pode ser melhor.

---

## Resumo final

**Helm é ideal quando você quer:**
- Reutilização
- Parametrização
- Versionamento
- Instalação e rollback simples

> **Helm transforma Kubernetes YAML em um pacote configurável.**
