# 🛠️ Hands-On 03 – Parte 1: Fundamentos e Ingress no Kubernetes

> Vamos praticar **Ingress** no **Kubernetes** usando **Minikube** e o **Nginx Ingress Controller**. Conteúdo direto para estudantes (sem roteiro de gravação).

---

## 📂 Estrutura de pastas

```bash
hands-on-03-parte1-ingress-kubernetes/
├── app-deployment.yaml       # Deployment da aplicação (Nginx)
├── app-service.yaml          # Service ClusterIP
├── app-ingress.yaml          # Ingress para roteamento externo
└── README.md                 # Instruções passo a passo
```

---

## 🎯 Objetivo

1) Subir um **cluster local** com **Minikube**.  
2) Criar um **Deployment** e um **Service (ClusterIP)** para um app simples (Nginx).  
3) **Habilitar** o **Nginx Ingress Controller** no Minikube.  
4) Criar um **Ingress** que roteia `http://<IP_DO_MINIKUBE>/meu-app` → `meu-app-web-service:80`.  
5) **Validar** o acesso via navegador/curl.  

---

## 🧰 Pré-requisitos

- **Docker Desktop** instalado (Windows/macOS) **ou** Docker Engine (Linux).  
- **Kubectl** instalado.  
- **Minikube** instalado.  

### 🔗 Links úteis de instalação
- **WSL (Windows Subsystem for Linux):** [Guia oficial Microsoft](https://learn.microsoft.com/pt-br/windows/wsl/install)  
- **Minikube para Windows:** [Download oficial](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download)  

### ✅ Windows: confirme o Docker Desktop com **WSL2** (recomendado)
1. **Abra o Docker Desktop** → ícone de engrenagem **Settings**.  
2. Em **General**, marque **Use the WSL 2 based engine** → **Apply & Restart**.  
3. Vá em **Resources → WSL Integration**:
   - Marque **Enable integration with my default WSL distro**.
   - Ative a sua distro (ex.: **Ubuntu**) na lista. **Apply & Restart**.
4. Valide no terminal (PowerShell/Windows Terminal):
   ```powershell
   wsl -l -v           # sua distro deve estar em "VERSION 2"
   docker version      # cliente e servidor devem responder
   ```
5. O Minikube usará o driver Docker do Docker Desktop. Você **não precisa** instalar Docker manualmente **dentro** do WSL para este hands-on.

---
### ⚙️ Validação da instalação (Windows)

Após instalar o **Minikube** e configurar o **Docker Desktop + WSL2**, valide no PowerShell:

```powershell
# 1. Verifique se o minikube.exe está no caminho
Test-Path 'C:\minikube\minikube.exe'

# 2. Adicione a pasta ao PATH desta sessão (se necessário)
$env:Path = "C:\minikube;$env:Path"

# 3. Teste a versão
minikube version
```
---

## 🚀 Passo a passo

### 1) Inicie o Minikube
```bash
minikube start --driver=docker
```
Verifique o status do cluster:
```bash
minikube status
kubectl cluster-info
```

### 2) Crie a aplicação (Deployment + Service)
Aplique os manifestos (já fornecidos neste repositório):
```bash
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml
```
Cheque pods e service:
```bash
kubectl get pods -l app=meu-app-web
kubectl get svc meu-app-web-service
```
> Você deve ver 2 Pods `Running` e um Service **ClusterIP** (sem `EXTERNAL-IP`).

### 3) Habilite o **Nginx Ingress Controller**
Ative o addon do Minikube:
```bash
minikube addons enable ingress
```
Aguarde os Pods do controlador ficarem `Running`:
```bash
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```
Descubra o **IP** do cluster:
```bash
minikube ip
```
> Anote esse IP – será usado nos testes (`http://<IP_DO_MINIKUBE>`).

---

### ⚠️ Importante para usuários Windows (Docker Desktop + WSL2)

O Minikube no Windows pode criar o Ingress Controller como `NodePort` por padrão, impedindo o acesso via navegador.  
Para corrigir, execute os comandos abaixo no **PowerShell (como Administrador)** **após habilitar o addon de ingress**:

```powershell
# Corrigir tipo do Ingress Controller (necessário no Windows)
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type":"LoadBalancer"}}'

# Abrir o túnel em outro terminal (como Administrador)
minikube tunnel
```

> 💡 **Dica:** mantenha o terminal com o túnel aberto enquanto testa o Ingress.  


---

### 4) Crie o **Ingress**
Aplique o Ingress (já fornecido neste repositório):
```bash
kubectl apply -f app-ingress.yaml
kubectl get ingress meu-app-ingress
```
Você deve ver um `ADDRESS` associado (normalmente o **IP do Minikube**).

### 5) Teste o acesso via Ingress
No **navegador** ou via **curl**:
```bash
curl http://<IP_DO_MINIKUBE>/meu-app
```
> Substitua `<IP_DO_MINIKUBE>` pelo IP obtido com `minikube ip`.

---

## 🧹 Limpeza (quando terminar)

```bash
kubectl delete -f app-ingress.yaml
kubectl delete -f app-service.yaml
kubectl delete -f app-deployment.yaml
minikube stop
minikube delete
```

---

## 🧭 Troubleshooting rápido

- **Ingress não responde / ADDRESS `<pending>`**
  - Aguarde ~1–2 minutos após habilitar o addon; confirme pods em `ingress-nginx`:
    ```bash
    kubectl get pods -n ingress-nginx
    ```
  - Confira IP do cluster:
    ```bash
    minikube ip
    kubectl get ingress
    ```
  - No Windows, se houver bloqueio, verifique o **Firewall**/VPN.

- **404 Not Found** ao acessar `/meu-app`
  - Verifique se o **path** no Ingress é `/meu-app` e se a annotation de **rewrite** está presente.  
  - Confirme **nome do Service** e **porta** no Ingress (`meu-app-web-service:80`).

- **Pods não sobem**
  - Veja eventos/logs: `kubectl describe pod <nome>` e `kubectl logs <nome-do-pod>`.

---

## 📚 Conceitos demonstrados

✅ Deployment (réplicas, atualização declarativa)  
✅ Service **ClusterIP** (acesso interno estável)  
✅ Nginx Ingress Controller (com Minikube addon)  
✅ Ingress (regra por **path** + reescrita de URL)  
✅ Fluxo de tráfego: **Ingress → Service → Pod**

---

## 🔭 Próxima aula (Parte 2 – Configuração do Nginx Ingress Controller e Roteamento)

**Tópicos:**  
3. Configuração do **Nginx Ingress Controller** no Kubernetes (parâmetros e boas práticas).  
4. **Roteamento por host e por path** (múltiplos serviços, reescrita de URL).  

**Hands-on:**  
- Criar **Ingress** para **múltiplos serviços** (ex.: `/app1`, `/app2` **e** hosts como `app.fiap.local`).  
- Testar **regras de roteamento** e **rewrite** com diferentes backends.

---

## 🔗 Referências oficiais

- Minikube: https://minikube.sigs.k8s.io/docs/  
- Kubernetes (Pods, Deployments, Services, Ingress): https://kubernetes.io/docs/concepts/  
- Nginx Ingress Controller: https://kubernetes.github.io/ingress-nginx/  
- Docker Desktop: https://docs.docker.com/desktop/

