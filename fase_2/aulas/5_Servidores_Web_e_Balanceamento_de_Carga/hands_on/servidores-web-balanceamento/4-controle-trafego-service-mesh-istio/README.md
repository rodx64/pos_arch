# Controle de Tráfego com Service Mesh (Istio) (Aula 4)

Este diretório contém os exemplos práticos (hands-on) da **Aula 4 – Controle de Tráfego com Service Mesh (Istio)**, organizados por vídeo para facilitar o acompanhamento durante as videoaulas.

---

## 🛠️ Pré-requisitos

Antes de iniciar os hands-on, certifique-se de ter instalado:

- **Minikube** (v1.30 ou superior) ou **Kind** → [Instalação Minikube](https://minikube.sigs.k8s.io/docs/start/) | [Instalação Kind](https://kind.sigs.k8s.io/)  
- **Kubectl** (v1.27 ou superior) → [Instalação](https://kubernetes.io/docs/tasks/tools/)  
- **Helm** (v3.12 ou superior) → [Instalação](https://helm.sh/docs/intro/install/)  
- **Git** → [Download](https://git-scm.com/downloads)  
- **Ferramentas de teste**:  
  - `curl` → [Documentação](https://curl.se/docs/install.html)  

✅ Verifique a instalação:
```bash
minikube version
kubectl version --client
helm version
git --version
curl --version
```

---

## 🚀 Como Usar Este Repositório

### 1. Clone o repositório
```bash
cd servidores-web-balanceamento-teste/4-controle-trafego-service-mesh-istio
```

### 2. Navegue pelas pastas dos vídeos
Cada pasta corresponde a uma parte da aula e contém:
- `README.md` com instruções específicas  
- Manifests YAML (`Deployment`, `Service`, `VirtualService`, `DestinationRule`, `PeerAuthentication`)  
- Arquivos de configuração adicionais  

### 3. Siga a sequência dos vídeos
📹 Parte 1: [Fundamentos e Arquitetura do Istio](./hands-on-04-parte1-istio/README.md)  
📹 Parte 2: [Roteamento Avançado e Deploy Gradual](./hands-on-04-parte2-istio-routing/README.md)  
📹 Parte 3: [Segurança e Observabilidade no Istio](./hands-on-04-parte3-istio-security-obs/README.md)  

---

## 🎯 Objetivos de Aprendizagem
Ao final desta aula você será capaz de:

✅ Compreender o conceito de **Service Mesh**  
✅ Entender a **arquitetura do Istio** (Control Plane e Data Plane)  
✅ Configurar **VirtualService** e **DestinationRule** para roteamento avançado  
✅ Implementar **Canary Deployment** e **A/B Testing** com Istio  
✅ Habilitar **mTLS em todo o mesh** e validar tráfego criptografado  
✅ Explorar ferramentas de **observabilidade no Istio** (Grafana, Jaeger, Kiali)  

---

## 📊 Tópicos Abordados
| Parte | Tópicos | Hands-on |
|-------|---------|----------|
| **1** | O que é Service Mesh, Arquitetura do Istio (Control Plane, Data Plane) | Instalar Istio em cluster local, validar pods, namespaces e sidecars |
| **2** | Roteamento avançado, VirtualService, DestinationRule, Canary, A/B Testing | Configurar VirtualService para roteamento canário (10%/90%) e A/B Testing por header |
| **3** | Segurança com mTLS, Observabilidade (métricas, tracing, logging) | Ativar mTLS, validar tráfego seguro, visualizar métricas (Grafana), traces (Jaeger) e topologia (Kiali) |

---

## 📚 Referências
- [Istio Documentation](https://istio.io/latest/docs/)  
- [VirtualService – Istio](https://istio.io/latest/docs/reference/config/networking/virtual-service/)  
- [DestinationRule – Istio](https://istio.io/latest/docs/reference/config/networking/destination-rule/)  
- [PeerAuthentication – Istio](https://istio.io/latest/docs/reference/config/security/peer_authentication/)  
- [Kiali](https://kiali.io/)  
- [Jaeger](https://www.jaegertracing.io/)  
