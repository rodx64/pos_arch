
# 🛠️ Hands-On 03 — Parte 2: Configuração e Roteamento no Nginx Ingress Controller

## 🎯 Objetivo
Implantar **duas aplicações** no Kubernetes e configurar **Ingress Resources** para rotear o tráfego por **hostname** e por **path**, incluindo **reescrita de URL** (rewrite).

---

## 📂 Estrutura de Arquivos (sugerida)
```
hands-on-03-parte2-ingress-routing/
├── app-frontend-deployment.yaml    # Deployment da aplicação Frontend
├── app-frontend-service.yaml       # Service da aplicação Frontend
├── app-api-deployment.yaml         # Deployment da aplicação API
├── app-api-service.yaml            # Service da aplicação API
├── ingress-host-routing.yaml       # Ingress para roteamento por host
├── ingress-path-routing.yaml       # Ingress para roteamento por path com regex + rewrite
└── README.md                       # Este guia
```

---

## 🔧 Pré‑requisitos
- **Minikube** instalado e iniciado (`minikube start --driver=docker`).
- **kubectl** instalado.
- **Nginx Ingress Controller** habilitado no Minikube:  
  ```bash
  minikube addons enable ingress
  kubectl get pods -n ingress-nginx
  ```

### 🔷 Especial **Windows** — `minikube tunnel`
Em alguns ambientes Windows (Docker Desktop + WSL2), o acesso ao Ingress fica mais estável com o túnel:
---

1) Abra um **PowerShell como Administrador** e execute (mantenha essa janela aberta):  
   ```powershell
    # 1. Verifique se o minikube.exe está no caminho esperado (ajuda a diagnosticar instalações manuais)
    Test-Path 'C:\minikube\minikube.exe'

    # 2. Adicione a pasta ao PATH apenas para ESTA sessão (caso o minikube não esteja no PATH do sistema)
    $env:Path = "C:\minikube;$env:Path"

    # 3. (Opcional) Verifique se o Docker está acessível; no Windows requer Docker Desktop em execução
    docker version

    # 4. Inicie o cluster Minikube utilizando o driver Docker (recomendado no Windows com Docker Desktop)
    minikube start --driver=docker

    # 5 Defina o driver Docker como padrão para futuros 'start'
    minikube config set driver docker

    # 6. Teste a versão instalada do Minikube (confirma que o binário está funcionando)
    minikube version

    # 7. Habilite o addon de Ingress Controller no Minikube (necessário para recursos Ingress)
    minikube addons enable ingress

    # 8. Liste os Pods do Ingress Controller para confirmar que ficaram em 'Running'
    kubectl get pods -n ingress-nginx

    # 9. Inicie o túnel para expor serviços do tipo LoadBalancer na máquina local (requer privilégios)
    minikube tunnel

   ```
2) Em outro PowerShell (normal), rode os demais comandos (`kubectl`, `curl`, etc.).

> Dica: você pode seguir **sem** o túnel usando `minikube ip`, mas o túnel evita variações de rede/Firewall/VPN no Windows e será necessário quando usarmos Service `LoadBalancer` em aulas futuras.

---

## 🚀 Passo a passo

### 1) Pegue o IP
```bash
minikube ip
# Anote o IP do Minikube: <MINIKUBE_IP>
```

### 2) Implemente as aplicações e Services
```bash
kubectl apply -f app-frontend-deployment.yaml
kubectl apply -f app-frontend-service.yaml
kubectl apply -f app-api-deployment.yaml
kubectl apply -f app-api-service.yaml
```

Verifique:
```bash
kubectl get pods -l app=app-frontend
kubectl get svc app-frontend-service
kubectl get pods -l app=app-api
kubectl get svc app-api-service
# Garanta Pods Running e Services como ClusterIP
```

### 3) Roteamento por **hostname**
Aplique o Ingress:
```bash
kubectl apply -f ingress-host-routing.yaml
kubectl get ingress host-based-ingress
```

Edite o arquivo **hosts** para apontar os nomes para o Minikube:

- **Linux/macOS**
  ```bash
  echo "<MINIKUBE_IP> frontend.local" | sudo tee -a /etc/hosts
  echo "<MINIKUBE_IP> api.local" | sudo tee -a /etc/hosts
  ```

- **Windows (PowerShell como Admin)**
  ```powershell
    # Abra o arquivo de hosts
    notepad C:\Windows\System32\drivers\etc\hosts

    # Adicione as linhas abaixo (com minikube tunnel ativo, mapeia para o loopback):
    127.0.0.1 frontend.local
    127.0.0.1 api.local

    # Dica: se NÃO estiver usando `minikube tunnel` (ex.: driver Hyper-V/VirtualBox),
    # use o IP do Minikube em vez de 127.0.0.1:
    # (descubra com) minikube ip
    # <MINIKUBE_IP> frontend.local
    # <MINIKUBE_IP> api.local
  ```

Teste:
```bash
# Linux/macOS
curl http://frontend.local
curl http://api.local

# Windows
curl.exe http://frontend.local
curl.exe http://api.local
```

### 4) Roteamento por **path** (com **regex** + **rewrite**)
> Para evitar conflito, remova o Ingress anterior:
```bash
kubectl delete -f ingress-host-routing.yaml
```

Aplique o Ingress por path (usa `use-regex: "true"` e `rewrite-target: /$2`):
```bash
kubectl apply -f ingress-path-routing.yaml
kubectl get ingress path-based-ingress
```

Atualize o **hosts** (se necessário):
- **Linux/macOS**
  ```bash
  echo "<MINIKUBE_IP> meuapp.local" | sudo tee -a /etc/hosts
  ```
- **Windows**
  ```powershell
    # Abra o arquivo de hosts
    notepad C:\Windows\System32\drivers\etc\hosts

    # Adicione a linha abaixo (com minikube tunnel ativo, mapeia para o loopback):
    127.0.0.1 meuapp.local

    # Dica: se NÃO estiver usando `minikube tunnel` (ex.: driver Hyper-V/VirtualBox),
    # use o IP do Minikube em vez de 127.0.0.1:
    # (descubra com) minikube ip
    # <MINIKUBE_IP> meuapp.local
  ```

Teste:
```bash
# Linux/macOS
curl http://meuapp.local/frontend
curl http://meuapp.local/api
curl http://meuapp.local/api/users

# Windows
curl.exe http://meuapp.local/frontend
curl.exe http://meuapp.local/api
curl.exe http://meuapp.local/api/users
```

> Observação: em `ingress-path-routing.yaml`, as rotas `/frontend(/|$)(.*)` e `/api(/|$)(.*)` funcionam com **captura de grupos** e reescrita para `/ $2`, preservando subpaths.

---

## 🧹 Limpeza
```bash
kubectl delete -f ingress-path-routing.yaml
kubectl delete -f app-frontend-deployment.yaml
kubectl delete -f app-frontend-service.yaml
kubectl delete -f app-api-deployment.yaml
kubectl delete -f app-api-service.yaml
minikube stop
# (opcional) minikube delete
```

---

## 📚 Conceitos demonstrados
- Deployments e Services para múltiplas aplicações.
- Ingress com **roteamento por Host**.
- Ingress com **roteamento por Path** (**Prefix** + regex + rewrite).
- Particularidades do **Windows** (arquivo `hosts` e `minikube tunnel`).
- Gerenciamento de tráfego centralizado com **Nginx Ingress Controller**.

---

## 🔭 Próximas aulas
**2 – TLS com cert-manager e Boas Práticas de Segurança**  
**Tópicos:**  
5. TLS com **cert-manager** e boas práticas de segurança.  

---

### Referências
- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Nginx Ingress Controller: https://kubernetes.github.io/ingress-nginx/
- Minikube: https://minikube.sigs.k8s.io/docs/start/
