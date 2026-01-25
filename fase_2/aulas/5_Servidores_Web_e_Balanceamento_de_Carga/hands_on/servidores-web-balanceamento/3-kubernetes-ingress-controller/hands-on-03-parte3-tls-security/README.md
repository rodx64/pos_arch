
# 🛠️ Hands-On 03 — Parte 3: TLS com cert-manager e Boas Práticas de Segurança (Cloud + Cloudflare)

Este hands-on pode ser feito em **qualquer provedor de nuvem (Kubernetes gerenciado)**.  
**No vídeo/execução**, foi usado **Scaleway Kapsule** (Kubernetes gerenciado): https://www.scaleway.com/en/  
Para DNS, usamos **Cloudflare** (ou outro DNS público equivalente).

> Por que nuvem? Os desafios ACME do Let's Encrypt precisam de **domínio público** e **IP público**.
>
> Fluxo: *Ingress NGINX (LoadBalancer público)* ↔ *DNS (A record no domínio)* ↔ *cert-manager*.

---

## 🎯 Objetivos
- Instalar o **NGINX Ingress Controller** (Service **LoadBalancer**).
- Instalar o **cert-manager** via Helm.
- Criar **ClusterIssuer** (Let’s Encrypt HTTP-01).
- Implantar app de exemplo (Nginx) + Service.
- Criar **Ingress** com **TLS** gerenciado pelo cert-manager.
- Validar **HTTPS** e, depois, aplicar boas práticas (redirect 80→443, HSTS).

---

## 🧰 Pré-requisitos
- **kubectl** configurado no cluster da sua nuvem (ex.: Scaleway Kapsule).
- **Helm** instalado: https://helm.sh/  
- **Domínio público** sob seu controle (ex.: `seu-dominio.com.br`) no seu DNS (ex.: Cloudflare).

> No hands-on, o provedor de cloud usado foi **Scaleway**: https://www.scaleway.com/en/

---

## 📁 Estrutura deste diretório
```
hands-on-03-parte3-tls-security/
├── README.md
├── app/
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   └── ingress-tls-app.yaml
├── cert-manager/
│   ├── cert-manager.sh                     # instala cert-manager (Helm)
│   └── clusterissuer-letsencrypt.yaml      # ClusterIssuer (Let’s Encrypt HTTP-01)
└── nginx_ingress_controller/
    └── nginx_ic.sh                         # instala ingress-nginx (Helm)
```

> Os scripts **.sh** são uma “cola” para acelerar a aula. Você pode rodá-los em **Linux/macOS** (bash) ou **Windows (Git Bash/WSL)**.  
> Se preferir, copie os comandos e execute manualmente.

---

## 🚀 Passo a passo

### 1) Ingress NGINX (LoadBalancer público)
Entre na pasta `nginx_ingress_controller/` e rode o script **ou** execute os comandos abaixo:

**Conteúdo do `nginx_ic.sh`:**
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Verifique o **EXTERNAL-IP** do LoadBalancer e **anote**:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
# Aguarde aparecer a coluna EXTERNAL-IP (ex.: 51.159.x.y)
```

### 2) DNS do seu domínio (Cloudflare)
Crie/ajuste o **A record** para o subdomínio do demo (ex.: `app.seu-dominio.com.br`) apontando para o **EXTERNAL-IP** do passo anterior.
- Em Cloudflare, deixe **DNS Only** (nuvem cinza) durante a emissão do certificado.
- Desative temporariamente: *Always Use HTTPS*, *HSTS* e *Automatic HTTPS Rewrites* enquanto estiver testando HTTP/HTTP-01.

Teste a resolução e conectividade:
```bash
nslookup app.seu-dominio.com.br
curl -v http://app.seu-dominio.com.br/
```

### 3) App + Service
Entre na pasta `app/` e aplique:
```bash
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml
kubectl get pods -l app=meu-app
kubectl get svc meu-app-service
```

### 4) cert-manager (Helm)
Entre na pasta `cert-manager/` e rode o script **ou** execute manualmente:

**Conteúdo do `cert-manager.sh`:**
```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.14.3 \
  --set installCRDs=true
```

### 5) ClusterIssuer (Let’s Encrypt — HTTP-01)
Edite **`cert-manager/clusterissuer-letsencrypt.yaml`** e troque o **e-mail** pelo seu (não use `example.com`). Exemplo de conteúdo:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: seu.email@dominio.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
      - http01:
          ingress:
            class: nginx
```
Aplique e confirme `Ready=True`:
```bash
kubectl apply -f cert-manager/clusterissuer-letsencrypt.yaml
kubectl get clusterissuer letsencrypt-prod -o wide
```

> **Dica:** se você editou o e-mail depois de aplicar, delete o Secret da conta ACME para forçar re-registro:  
> `kubectl -n cert-manager delete secret letsencrypt-prod-private-key`

### 6) Ingress com TLS gerenciado
Edite **`app/ingress-tls-app.yaml`**, trocando `<SEU_DOMINIO>` pelo seu host (ex.: `app.seu-dominio.com.br`). Use o `ClusterIssuer` acima e **deixe o redirect OFF** durante a emissão (HTTP-01 precisa servir `/.well-known/acme-challenge/*` em HTTP).

Exemplo:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    acme.cert-manager.io/http01-edit-in-place: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.seu-dominio.com.br
      secretName: meu-app-tls-secret
  rules:
    - host: app.seu-dominio.com.br
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: meu-app-service
                port:
                  number: 80
```
Aplique e monitore:
```bash
kubectl apply -f app/ingress-tls-app.yaml

# Observe a emissão
kubectl get certificate,certificaterequest,order,challenge -A
kubectl describe certificate meu-app-tls-secret -n default
kubectl logs -f -n cert-manager $(kubectl get pods -n cert-manager -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')
```

Quando o Secret `meu-app-tls-secret` tiver `tls.crt`/`tls.key`, teste:
```bash
curl -vkI https://app.seu-dominio.com.br
```

### 7) Ative redirect e HSTS (produção)
Depois de validar o HTTPS:
```bash
kubectl annotate ingress host-based-ingress \
  nginx.ingress.kubernetes.io/ssl-redirect="true" \
  nginx.ingress.kubernetes.io/force-ssl-redirect="true" \
  nginx.ingress.kubernetes.io/hsts="true" \
  nginx.ingress.kubernetes.io/hsts-max-age="31536000" --overwrite
```

---

## 🧪 Troubleshooting (curto)
- **404 Not Found no Ingress** → confirme `ingressClassName: nginx`; Service com **endpoints** (labels/selector corretos).
- **Webhook x509: unknown authority** ao criar Ingress → reinstale o ingress-nginx no namespace padrão `ingress-nginx` e deixe o chart recriar os secrets do admission.
- **Redirect indesejado para HTTPS** → desligue `ssl-redirect/force-ssl-redirect`, e no Cloudflare deixe **DNS Only** e **desative** Always HTTPS/HSTS durante os testes.
- **Issuer travado (invalidContact example.com)** → troque o e-mail por um válido e delete o Secret da conta ACME para re-registrar.
- **Challenge não aparece** → use `acme.cert-manager.io/http01-edit-in-place: "true"` no Ingress para o próprio Ingress responder `/.well-known/acme-challenge/*`.

---

## 🧹 Limpeza e **custo**
Para **evitar custos** (LB, nós, IP público), remova tudo quando terminar:

```bash
# App e Ingress
kubectl delete -f app/ingress-tls-app.yaml
kubectl delete -f app/app-service.yaml
kubectl delete -f app/app-deployment.yaml

# ClusterIssuer e cert-manager
kubectl delete -f cert-manager/clusterissuer-letsencrypt.yaml || true
helm uninstall cert-manager -n cert-manager || true
kubectl delete ns cert-manager || true

# Ingress NGINX
helm uninstall ingress-nginx -n ingress-nginx || true
kubectl delete ns ingress-nginx || true

# (opcional) excluir o cluster da nuvem (ex.: Scaleway Kapsule) e remover o A record do DNS
```
> ⚠️ Não esqueça de **apagar o A record** no seu DNS (Cloudflare) e **destruir o cluster**/recursos na sua nuvem para não gerar custo contínuo.

---

### ✅ Resumo
1. Instale **ingress-nginx** (LB público) → pegue o **EXTERNAL-IP**.  
2. Aponte DNS do seu host para esse IP (**DNS Only**).  
3. Aplique **app + service**.  
4. Instale **cert-manager** e aplique o **ClusterIssuer** (e-mail real).  
5. Aplique o **Ingress** com `cluster-issuer` + `tls` (redirect OFF) → cert é emitido.  
6. Valide **HTTPS** e **ative redirect/HSTS** para produção.  
7. Faça a **limpeza** para não gerar custos extras.
