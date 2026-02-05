# Helm vs Kustomize — Comparativo Prático no Kubernetes

Este documento compara **Helm** e **Kustomize** de forma objetiva, focando em **quando usar cada um**, **o que resolvem** e **como se complementam** em ambientes reais.

---

## Visão geral

| Ferramenta | O que é |
|-----------|--------|
| **Helm** | Gerenciador de pacotes do Kubernetes baseado em templates |
| **Kustomize** | Ferramenta de customização declarativa de YAML |

---

## Filosofia

### Helm
- Baseado em **templates**
- YAML é gerado dinamicamente
- Focado em **reuso e distribuição**
- Mais flexível, mais complexo

### Kustomize
- Trabalha com **YAML puro**
- Não gera recursos novos, apenas transforma
- Focado em **customização por ambiente**
- Simples e previsível

---

## Comparação direta

| Critério | Helm | Kustomize |
|--------|------|-----------|
| Tipo | Template engine | Transformer |
| YAML | Gerado | Puro |
| Variáveis | Sim | Não |
| Lógica condicional | Sim (`if`, `range`) | Não |
| Curva de aprendizado | Média/Alta | Baixa |
| Reuso | Muito alto | Médio |
| Overlays por ambiente | Via values | Nativo |
| Versionamento | Charts + releases | Git |
| Rollback | Nativo | Via Git |
| Instalável via kubectl | Não | Sim |

---

## Estrutura típica

### Helm

```
todo-api/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   └── service.yaml
```

### Kustomize

```
k8s/
├── base/
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── dev/
    └── prod/
```

---

## Exemplo prático: réplicas por ambiente

### Helm

`values.yaml`
```yaml
replicaCount: 1
```

`values-prod.yaml`
```yaml
replicaCount: 5
```

Template:
```yaml
replicas: {{ .Values.replicaCount }}
```

---

### Kustomize

`base/deployment.yaml`
```yaml
replicas: 1
```

`overlays/prod/kustomization.yaml`
```yaml
replicas:
  - name: todo-api
    count: 5
```

---

## Onde cada um brilha

### Use Helm quando:
- Você distribui a aplicação para outros times/clientes
- Precisa de muita parametrização
- Mantém um produto (chart) versionado
- Quer rollback automático

### Use Kustomize quando:
- A aplicação é interna
- Você quer YAML simples
- Diferença é basicamente por ambiente
- Você usa GitOps

---

## Usando Helm e Kustomize juntos (mundo real)

Sim, **eles não são concorrentes diretos**.

### Estratégia comum

1. Helm gera os manifests base
2. Kustomize aplica overlays por ambiente

Exemplo:
```
helm template todo-api ./chart > base.yaml
kustomize build overlays/prod
```

Ou no ArgoCD:
- Chart Helm
- Overlays Kustomize por ambiente

---

## Integração com GitOps

| Ferramenta | Helm | Kustomize |
|-----------|------|-----------|
| ArgoCD | Suporte nativo | Suporte nativo |
| FluxCD | Suporte nativo | Suporte nativo |

Diferença:
- Helm controla release
- Kustomize controla estado desejado via Git

---

## Erros comuns

### Helm
❌ Templates complexos demais  
❌ Lógica difícil de debugar  
❌ Charts genéricos mal documentados  

### Kustomize
❌ Patches demais  
❌ Base muito opinativa  
❌ Falta de padronização  

---

## Regra de ouro

> **Helm cria o pacote.  
> Kustomize adapta o pacote ao ambiente.**

Ou mais simples:

- **Produto** → Helm
- **Ambiente** → Kustomize

---

## Conclusão

Não existe “melhor ferramenta”.

Existe:
- Contexto
- Time
- Maturidade
- Escala

Equipes maduras normalmente usam **Helm + Kustomize juntos**, cada um resolvendo um problema diferente.
