# Kustomize no Kubernetes — Guia Prático e Explicado

## O que é o Kustomize?

**Kustomize** é uma ferramenta nativa do Kubernetes usada para **customizar manifests YAML sem duplicar arquivos e sem usar templates**.

Ele permite que você tenha:
- Um conjunto **base** de recursos Kubernetes
- **Overlays** que aplicam diferenças por ambiente (dev, stage, prod)

Tudo isso mantendo:
- YAML puro
- Estrutura clara
- Versionamento simples
- Integração direta com `kubectl`

---

## Qual problema o Kustomize resolve?

Em projetos reais, você precisa do **mesmo aplicativo** rodando em **ambientes diferentes**, com pequenas variações:

- Quantidade de réplicas
- Tag da imagem
- Variáveis de ambiente
- ConfigMaps
- Secrets
- Namespace

❌ Abordagem ruim (copiar YAML):
- Duplicação
- Drift entre ambientes
- Manutenção difícil

✅ Kustomize:
- Reuso
- Diferenças explícitas
- Zero template

---

## Conceito central

> **Base comum + Overlays com diferenças**

O Kustomize **lê YAMLs existentes** e aplica **transformações declarativas**.

Ele **não executa lógica**, apenas transforma manifests.

---

## Estrutura de diretórios típica

```
k8s/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

---

## Base (definição comum)

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: todo-api
  template:
    metadata:
      labels:
        app: todo-api
    spec:
      containers:
        - name: todo-api
          image: todo-api:latest
          ports:
            - containerPort: 3000
```

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: todo-api
spec:
  selector:
    app: todo-api
  ports:
    - port: 80
      targetPort: 3000
```

### kustomization.yaml (base)

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

---

## Overlay DEV

```yaml
resources:
  - ../../base

namespace: dev

replicas:
  - name: todo-api
    count: 1

images:
  - name: todo-api
    newTag: latest
```

---

## Overlay PROD

```yaml
resources:
  - ../../base

namespace: prod

replicas:
  - name: todo-api
    count: 5

images:
  - name: todo-api
    newTag: v1.3
```

---

## Aplicando

```bash
kubectl apply -k overlays/dev
kubectl apply -k overlays/prod
```

---

## Resumo

**Kustomize** permite customizar YAMLs Kubernetes por ambiente:
- sem duplicar arquivos
- sem templates
- usando apenas YAML

> Base define o comum, overlay define a diferença.
