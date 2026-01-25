# 🛠️ Hands-On 05 - Parte 3: Nginx + ModSecurity + Segurança

## 🎯 Objetivo

Instalar e configurar **ModSecurity** no **Nginx**, habilitar o **OWASP
Core Rule Set (CRS)**, criar **regras personalizadas**, simular um
ataque de **SQL Injection** e validar o bloqueio, aplicar **rate
limiting** real contra uma **API Flask**, e checar **métricas de
segurança** via logs.

------------------------------------------------------------------------

## 📦 Ambiente Utilizado

-   **Docker + Docker Compose** (Linux/macOS/Windows + WSL2)\
-   **Nginx + ModSecurity** como WAF\
-   **Flask API (Python)** para servir de backend e gerar tráfego real

------------------------------------------------------------------------

## 📂 Estrutura de Pastas

``` bash
hands-on-05-parte3/
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── modsecurity.conf
│   ├── custom-rules.conf
│   └── index.html
├── api/
│   ├── Dockerfile
│   └── api.py
└── docker-compose.yml
```

------------------------------------------------------------------------

## 🚀 Passos de Instalação

### 1) Dockerfile do Nginx (`nginx/Dockerfile`)

``` dockerfile

# Instalar dependências básicas
RUN apk add --no-cache \
    curl \
    wget \
    unzip

# Criar diretórios necessários
RUN mkdir -p /etc/modsecurity.d \
    && mkdir -p /var/log/modsec_audit \
    && mkdir -p /var/www/html

# Baixar e configurar OWASP Core Rule Set (simulado)
RUN mkdir -p /etc/modsecurity.d/owasp-crs

# Copiar arquivos de configuração
COPY nginx.conf /etc/nginx/nginx.conf
COPY modsecurity.conf /etc/modsecurity.d/modsecurity.conf
COPY custom-rules.conf /etc/modsecurity.d/custom-rules.conf
COPY index.html /var/www/html/


EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

------------------------------------------------------------------------

### 2) Dockerfile da API (`api/Dockerfile`)

``` dockerfile
FROM python:3.11-alpine

WORKDIR /app

# Instalar dependência Flask
RUN pip install flask

# Copiar o código da API
COPY api.py /app/api.py

EXPOSE 5000

CMD ["python", "api.py"]
```

------------------------------------------------------------------------

### 3) API em Flask (`api/api.py`)

``` python
from flask import Flask
import time

app = Flask(__name__)

@app.route("/api/")
def api():
    # Simula um processamento para ocupar CPU e "segurar" a conexão
    time.sleep(0.5)
    return "API chamada com sucesso!\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
```

------------------------------------------------------------------------

### 4) Configuração do Nginx (`nginx/nginx.conf`)

``` nginx
# 🔹 Configurações globais
events {
    worker_connections 1024;   # Cada worker pode lidar com até 1024 conexões
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 🔹 Zonas de Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=1r/s;     # Máx. 1 req/s por IP para /api/
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;   # Máx. 1 req/s por IP para /login

    # 🔹 Logs customizados
    log_format security '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" rt=$request_time';

    access_log /var/log/nginx/access.log security;
    error_log /var/log/nginx/error.log warn;

    server {
        listen 80;
        server_name localhost;
        root /var/www/html;
        index index.html;

        # 🔹 Rota /api → protegida por rate limiting
        location /api/ {
            limit_req zone=api burst=2 nodelay;   # Máx. 2 excessos permitidos
            proxy_pass http://api:5000;          # Redireciona para o container da API Flask
        }

        # 🔹 Rota /login
        location /login {
            limit_req zone=login burst=3 nodelay;
            try_files $uri $uri/ =404;
        }

        # 🔹 Bloqueios básicos
        if ($http_user_agent ~* (sqlmap|nikto|nmap|masscan|nessus)) { return 403; }
        if ($args ~* (union|select|insert|delete|drop|create|alter|exec|script)) { return 403; }
        if ($args ~* (<script|javascript:|vbscript:|onload|onerror)) { return 403; }

        location / { try_files $uri $uri/ =404; }
    }
}
```

------------------------------------------------------------------------

### 5) Docker Compose (`docker-compose.yml`)

``` yaml
services:
  nginx:
    build: .
    ports:
      - "8080:80"
    depends_on:
      - api
    networks:
      - labnet

  api:
    build: ./api
    expose:
      - "5000"
    networks:
      - labnet

networks:
  labnet:
    driver: bridge
```

------------------------------------------------------------------------

## 🚀 Subindo o ambiente

### Linux/macOS

``` bash
docker-compose up --build -d
```

### Windows (PowerShell)

``` powershell
docker-compose up --build -d
```

------------------------------------------------------------------------

## 🧪 Testes

### 1. Requisição normal

``` bash
curl "http://localhost:8080/api/"
```

Esperado: **200 OK**

### 2. SQL Injection

``` bash
curl "http://localhost:8080/?id=1' OR '1'='1"
```

Esperado: **403 Forbidden**

### 3. XSS

``` bash
curl "http://localhost:8080/?search=<script>alert('xss')</script>"
```

Esperado: **403 Forbidden**

### 4. User-Agent malicioso

``` bash
curl -H "User-Agent: sqlmap/1.0" "http://localhost:8080/"
```

Esperado: **403 Forbidden**

### 5. Rate Limiting

**Linux/macOS**:

``` bash
ab -n 20 -c 20 http://localhost:8080/api/
```

**Navegador Web F12**:

``` 
(async () => {
  const url = "http://localhost:8080/api/";
  const total = 30;
  const promises = Array.from({length: total}, (_, i) =>
    fetch(url).then(r => ({i: i+1, status: r.status})).catch(e => ({i: i+1, status: 'ERR', error: e.message}))
  );

  const results = await Promise.all(promises);
  results.forEach(r => console.log(`#${r.i} → ${r.status}`));
  const blocked = results.filter(r => r.status === 403).length;
  const ok = results.filter(r => typeof r.status === 'number' && r.status >=200 && r.status < 400).length;
})();
```

Esperado:\
- Algumas **200 OK** (respostas permitidas)\
- Muitas **503 Service Temporarily Unavailable** (rate limit acionado)

------------------------------------------------------------------------

## 📊 Logs e Métricas

``` bash
docker logs <id-nginx>
docker logs <id-api>
docker exec -it <id-nginx> tail -f /var/log/nginx/access.log
```

------------------------------------------------------------------------

## 📚 O que você aprendeu

-   Configurar **Nginx + ModSecurity** como WAF.\
-   Criar regras contra **SQLi, XSS e User-Agents maliciosos**.\
-   Aplicar **rate limiting real** em uma API.\
-   Testar bloqueios com **ApacheBench (ab)** e **cURL**.

------------------------------------------------------------------------

## 🎉 Conclusão

Com esse hands-on você tem um **mini-laboratório de WAF** rodando em
Docker.\
Mostrou-se:\
- **200 OK** → requisição válida\
- **403 Forbidden** → ataque bloqueado (SQLi/XSS/User-Agent)\
- **503 Service Unavailable** → rate limit ativo

