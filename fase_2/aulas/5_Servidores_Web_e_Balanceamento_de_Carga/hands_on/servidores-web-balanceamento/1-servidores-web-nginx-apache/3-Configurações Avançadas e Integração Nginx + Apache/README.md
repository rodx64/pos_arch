# 🛠️ Hands-On 03: Nginx + Apache – Integração e Otimização

## 🎯 Objetivo
Integrar **Nginx como Proxy Reverso** para **Apache**, habilitar **cache no Nginx** e praticar **reescrita de URLs (mod_rewrite)** no Apache.  
Opcionalmente, comentar **cache no Apache (mod_cache)**.

Você vai entender:
1. `proxy_pass` do Nginx para backend Apache.  
2. `proxy_cache` no Nginx (verificar `HIT/MISS`).  
3. `.htaccess` + `mod_rewrite` no Apache para URLs amigáveis.  
4. (Opcional) Diretrizes para `mod_cache` no Apache.  

> **Nota:** Este cenário simula produção:  
> - Nginx na borda (porta **80**)  
> - Apache como backend interno (porta **8081**).  

---

## 🔎 Papéis de cada servidor

| Componente | Responsabilidade |
|------------|------------------|
| **Nginx**  | Proxy reverso, cache de respostas, entrega de conteúdo estático em `/static/` |
| **Apache** | Processamento dinâmico (PHP), reescrita de URLs amigáveis com `.htaccess`, resposta de páginas dinâmicas |

---

## 📂 Estrutura do Projeto

```
hands-on-03-nginx-apache-integration/
├── docker-compose.yml
├── Dockerfile.apache
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── reverse-proxy.conf
│       └── cache-zone.conf
├── nginx-static-content/
│   └── nginx-static.html
└── apache-backend/
    ├── apache-config/
    │   ├── httpd-vhosts.conf         
    │   ├── 000-default.conf          
    │   └── apache2.conf              
    ├── html/
    │   ├── index.html
    │   ├── user.php
    │   ├── .htaccess
    │   ├── big-image.jpg
    │   └── new-page.html             
    └── logs/                         
        ├── access.log
        └── error.log
└── README.md
```

---

## 🚀 Como Executar

### Pré-requisitos
- Docker e Docker Compose instalados.
- Se houver Apache/NGINX rodando na máquina, pare-os para evitar conflito de portas.

### Passo a passo

1. **Subir o ambiente**  
   ```bash
   docker-compose up -d --build
   ```

2. **Checar os serviços**  
   ```bash
   docker-compose ps
   ```

3. **Acessar no navegador**:
   - Via **Nginx (proxy para Apache)** → http://localhost:8080  
   - **Estático direto no Nginx** → http://localhost:8080/static/nginx-static.html  
   - **URL amigável (rewrite)** → http://localhost:8080/user/123 (tente outros IDs)  
   - **Redirecionamento** → http://localhost:8080/old-page.html  
   - **Apache direto (debug)** → http://localhost:8081  

4. **Recarregar configs**  
   ```bash
   docker-compose exec nginx-reverse-proxy nginx -s reload
   docker-compose restart apache-backend
   ```

5. **Ver logs**  
   ```bash
   docker-compose logs -f nginx-proxy
   docker-compose logs -f apache-backend
   ```

6. **Encerrar**  
   ```bash
   docker-compose down
   ```

---

## 🧪 Testes Práticos

### 1. Verificar cache (DevTools)
Abra F12 → **Network** → selecione a request → veja o header `X-Proxy-Cache`:  
- `MISS` → primeira requisição  
- `HIT` → requisições seguintes  

### 2. Testar via terminal

**Windows PowerShell:**
```powershell
curl.exe -o NUL -s -w "Tempo Total: %{time_total}`n" http://localhost:8080/
curl.exe -I http://localhost:8080/ | findstr /R /C:"X-Proxy-Cache" /C:"Cache-Control" /C:"Age"
```

🔎 Saída esperada:
- Primeira requisição → `X-Proxy-Cache: MISS`
- Segunda requisição → `X-Proxy-Cache: HIT`

**Linux/macOS:**
```bash
curl -o /dev/null -s -w "Tempo Total: %{time_total}\n" http://localhost:8080/
curl -I http://localhost:8080/ | egrep -i "X-Proxy-Cache|Cache-Control|Age"
```

### 3. ApacheBench (se instalado)
```bash
ab -n 100 -c 10 http://localhost:8080/user/123
```

---

## 📖 Exemplos Esperados

- `http://localhost:8080/user/123`  
  ```
  Página do Usuário
  Bem-vindo, usuário ID: 123
  ```

- `http://localhost:8080/old-page.html`  
  → Redireciona automaticamente para `/index.html`.

- `http://localhost:8080/static/nginx-static.html`  
  → Página simples entregue diretamente pelo Nginx.

---

## 📚 Conceitos Fixados

- ✅ Nginx como Proxy Reverso  
- ✅ Cache de respostas no Nginx (HIT/MISS)  
- ✅ Reescrita de URLs no Apache com `.htaccess`  
- ✅ Separação de responsabilidades (Nginx na borda, Apache no backend)  
- ✅ Servindo conteúdo estático direto pelo Nginx  

---

## ⚠️ Erros Comuns

- **502 Bad Gateway** → backend Apache parado ou `proxy_pass` incorreto.  
- **Arquivo PHP exibido cru** → imagem errada (`httpd:2.4` em vez de `php:8.2-apache`).  
- **`.htaccess` não funciona** → falta `AllowOverride All` no `apache2.conf` ou no VirtualHost.  
- **Cache não dá HIT** → verificar permissões em `/var/cache/nginx` e diretiva `proxy_cache_path`.  
- **Conflito de portas** → liberar portas 80 e 8081 antes de subir os containers.  

---

## 🔮 Próximos Passos

Na próxima parte, vamos dar início à **Aula 2 – Balanceamento de Carga na Prática**, utilizando o Nginx para distribuir requisições entre múltiplos backends.

---

## 🎓 Dica do Professor

Antes de avançar, tente os seguintes desafios extras:
- Criar um novo rewrite:  
  `/hello/NOME → hello.php?name=NOME`  
- Alterar o tempo de cache no Nginx (`proxy_cache_valid`) e medir o impacto nos tempos de resposta.  
- Ativar o `mod_expires` no Apache para controlar cache de imagens.  
