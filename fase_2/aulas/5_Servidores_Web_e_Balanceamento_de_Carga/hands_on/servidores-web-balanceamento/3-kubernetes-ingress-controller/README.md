# Gerenciamento de Tráfego no Kubernetes com Nginx Ingress Controller (Aula 3)

Este diretório contém os exemplos práticos (hands-on) da **Aula 3 – Gerenciamento de Tráfego no Kubernetes com Nginx Ingress Controller**, organizados por vídeo para facilitar o acompanhamento durante as videoaulas.

---

## 🛠️ Pré-requisitos

Antes de iniciar os hands-on, certifique-se de ter instalado:

- **Minikube** (v1.30 ou superior) → [Instalação](https://minikube.sigs.k8s.io/docs/start/)  
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
cd servidores-web-balanceamento-teste/3-kubernetes-ingress-controller
```

### 2. Navegue pelas pastas dos vídeos
Cada pasta corresponde a uma parte da aula e contém:
- `README.md` com instruções específicas  
- Manifests YAML (`Deployment`, `Service`, `Ingress`)  
- Arquivos de configuração adicionais  

### 3. Siga a sequência dos vídeos
📹 Parte 1: [Fundamentos e Ingress no Kubernetes](./hands-on-03-parte1-ingress-kubernetes/README.md)  
📹 Parte 2: [Configuração do Nginx Ingress Controller e Roteamento](./hands-on-03-parte2-ingress-routing/README.md)  
📹 Parte 3: [TLS com cert-manager e Boas Práticas de Segurança](./hands-on-03-parte3-tls-security/README.md)  

---

## 🎯 Objetivos de Aprendizagem
Ao final desta aula você será capaz de:

✅ Revisar os **fundamentos de containers e Kubernetes**  
✅ Entender o que é um **Ingress no Kubernetes** e por que utilizá-lo  
✅ Configurar o **Nginx Ingress Controller** no cluster  
✅ Implementar **roteamento baseado em host e path**  
✅ Configurar **TLS com cert-manager** para habilitar HTTPS  
✅ Aplicar **boas práticas de segurança em Ingress**  

---

## 📊 Tópicos Abordados
| Parte | Tópicos | Hands-on |
|-------|---------|----------|
| **1** | Fundamentos de Containers e Kubernetes, Conceito de Ingress | Criar Deployment e Service no Minikube, habilitar o Ingress Controller e validar pods |
| **2** | Configuração do Nginx Ingress Controller, Roteamento por Host e Path | Criar Ingress Resource para múltiplos serviços, testar roteamento e reescrita de URL |
| **3** | TLS com cert-manager, Boas Práticas de Segurança | Instalar cert-manager, criar ClusterIssuer, configurar Ingress com TLS e validar acesso seguro |

---

## 📚 Referências
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)  
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)  
- [Cert-Manager](https://cert-manager.io/docs/)  
