# 🛠️ Hands-On 02: Nginx Básico, Server Blocks e Comparativo com Apache

## 🎯 Objetivo

Neste exercício você vai **configurar o servidor Nginx dentro de um container Docker**, entendendo:

1. Como funciona a configuração principal do Nginx (`nginx.conf`).  
2. Como criar **Server Blocks** (equivalente ao Virtual Host do Apache).  
3. Como hospedar **múltiplos sites** na mesma instância do Nginx.  
4. Como comparar o desempenho do Nginx com o Apache no **serving de arquivos estáticos**.  

O objetivo é **visualizar na prática** os conceitos de desempenho e múltiplos sites.

---

## 📂 Estrutura do Projeto

```
hands-on-02-nginx/
├── Dockerfile.apache          # Dockerfile para subir Apache customizado
├── docker-compose.yml         # Orquestra os containers
├── apache/
│   ├── html/                  # Conteúdo servido pelo Apache (porta 8080)
│   │   ├── index.html
│   │   └── big-image.jpg
│   ├── httpd-vhosts.conf      # Configuração dos Virtual Hosts no Apache
│   └── logs/                  # Logs de acesso e erro
├── html1/                     # Site 1 (Nginx, porta 80)
│   ├── index.html
│   ├── style.css
│   └── big-image.jpg
├── html2/                     # Site 2 (Nginx, porta 81)
│   ├── index.html
│   └── style.css
└── nginx/
    ├── nginx.conf             # Configuração principal do Nginx
    └── conf.d/
        ├── site1.conf         # Server block para o Site 1
        └── site2.conf         # Server block para o Site 2
```

---

## 🚀 Como Executar

### Pré-requisitos

- Docker instalado  
- Docker Compose instalado  

---

### 🔧 Passo 1: Subindo os Containers

1. Vá para a pasta do projeto:

   ```bash
   cd hands-on-02-nginx
   ```

2. Suba os containers:

   ```bash
   docker-compose up -d --build
   ```

3. Verifique se estão rodando:

   ```bash
   docker ps
   ```

Saída esperada (resumida):

```
CONTAINER ID   IMAGE              COMMAND                  PORTS
xyz123abc456   nginx:1.25.3-alpine "nginx -g 'daemon of…"   0.0.0.0:80->80/tcp, 0.0.0.0:81->81/tcp
abc456def789   apache:custom       "httpd-foreground"       0.0.0.0:8080->80/tcp
```

---

### ⚙️ Passo 2: Acessando os Sites

- 👉 Site 1 (Nginx): http://localhost:8088  
- 👉 Site 2 (Nginx): http://localhost:8081  
- 👉 Apache (para comparação): http://localhost:8080  

---

### 📊 Passo 3: Comparando Apache x Nginx

#### Usando `curl`

```bash
curl -I http://localhost:80/big-image.jpg   # Nginx
curl -I http://localhost:8080/big-image.jpg # Apache
```

Observe os headers e o tempo de resposta.

#### Usando `ab` (Apache Benchmark)

Exemplo: 100 requisições, 10 concorrentes:

```bash
ab -n 100 -c 10 http://localhost:8088/big-image.jpg   # Nginx
ab -n 100 -c 10 http://localhost:8080/big-image.jpg # Apache
```

Compare o `Requests per second` e o `Time per request`.

---

## 📚 Conceitos Demonstrados

✅ Estrutura básica do Nginx (`nginx.conf`)  
✅ Server Block (Virtual Host no Nginx)  
✅ Location block e `try_files`  
✅ Servindo arquivos estáticos  
✅ Hospedando múltiplos sites no mesmo servidor  
✅ Comparação de performance entre Apache e Nginx  

---

## ⚠️ Erros Comuns

- **Porta 80, 81 ou 8080 já em uso** → altere no `docker-compose.yml`.  
- **Erro 404** → confirme se os arquivos `index.html` e `big-image.jpg` estão no lugar certo.  
- **Apache não sobe** → revise o `Dockerfile.apache` e o `httpd-vhosts.conf`.  
- **Configuração do Nginx não aplicou** → rode `nginx -s reload` dentro do container.  

---

## 🔮 Próximos Passos

No próximo hands-on vamos explorar **balanceamento de carga com Nginx**, adicionando múltiplos backends e observando como o Nginx distribui requisições entre eles.

---

📌 **Explicação para o aluno:**  
Este exercício mostra **na prática** por que o Nginx é mais rápido para servir arquivos estáticos, além de como ele facilita a configuração de múltiplos sites com poucos blocos de configuração.  
Já o Apache, mesmo robusto e flexível, pode consumir mais recursos em cenários de muitas conexões simultâneas.  
