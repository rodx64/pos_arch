# 🛠️ Hands-On 03: Apache com Docker Compose e Virtual Hosts

## 🎯 Objetivo

Neste exercício você vai **configurar o servidor Apache HTTP Server** dentro de um container Docker, entendendo:

1. Como funciona a configuração principal do Apache (`httpd.conf`).
2. Como criar **Virtual Hosts**, permitindo hospedar **múltiplos sites** em um único servidor.
3. Como mapear **volumes** no Docker para personalizar configuração, sites e logs.

O objetivo é **visualizar na prática** os conceitos de servidores web, modularidade do Apache e hospedagem de múltiplos sites.

---

## 📂 Estrutura do Projeto

```
hands-on-03-apache/
├── apache/
│   └── httpd.conf          # Arquivo de configuração principal do Apache
├── sites/
│   ├── site1.local/        # Primeiro site hospedado (Virtual Host 1)
│   │   └── index.html
│   └── site2.local/        # Segundo site hospedado (Virtual Host 2)
│       └── index.html
├── logs/                   # Diretório para logs de erros e acessos
├── docker-compose.yml
└── README.md
```

**Explicação para o aluno:**  
- A pasta `apache/` contém as regras de configuração do servidor.  
- A pasta `sites/` tem os arquivos de cada site hospedado.  
- A pasta `logs/` armazena o que acontece dentro do servidor (acessos e erros).  
- O `docker-compose.yml` orquestra tudo.  

---

## 🚀 Como Executar

### Pré-requisitos

- Docker instalado  
- Docker Compose instalado  

---

### 🔧 Passo 1: Subindo o Apache com Docker

1. Vá para a pasta do projeto:

   ```bash
   cd hands-on-03-apache
   ```

2. Suba o container:

   ```bash
   docker-compose up -d
   ```

3. Verifique se o Apache está rodando:

   ```bash
   docker ps
   ```

   Saída esperada:

   ```
   CONTAINER ID   IMAGE              COMMAND              PORTS                  NAMES
   abc123def456   httpd:2.4-alpine   "httpd-foreground"   0.0.0.0:8080->80/tcp   apache-server
   ```

---

### ⚙️ Passo 2: Configuração do Apache

O arquivo `apache/httpd.conf` define como o servidor deve se comportar:

- **Listen 80** → Apache escuta na porta 80.  
- **LoadModule** → O Apache é modular, só carrega os módulos necessários.  
- **<VirtualHost>** → Cria um “site dentro do servidor”.  

Exemplo dos blocos de Virtual Host configurados:

```apache
<VirtualHost *:80>
    ServerName site1.local
    DocumentRoot "/usr/local/apache2/htdocs/site1.local"

    <Directory "/usr/local/apache2/htdocs/site1.local">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog "logs/site1.local_error.log"
    CustomLog "logs/site1.local_access.log" common
</VirtualHost>

<VirtualHost *:80>
    ServerName site2.local
    DocumentRoot "/usr/local/apache2/htdocs/site2.local"

    <Directory "/usr/local/apache2/htdocs/site2.local">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog "logs/site2.local_error.log"
    CustomLog "logs/site2.local_access.log" common
</VirtualHost>
```

**Explicação:**  
- `site1.local` e `site2.local` são domínios simulados, resolvidos localmente.  
- Cada Virtual Host tem seu próprio diretório e logs separados.  

---

### 🌐 Passo 3: Configuração dos Sites

Crie dois arquivos simples para diferenciar os sites:  

**sites/site1.local/index.html**
```html
<h1>🌐 Site 1 - Corporativo</h1>
<p>Hospedado via Apache Virtual Host!</p>
```

**sites/site2.local/index.html**
```html
<h1>✍️ Site 2 - Blog Pessoal</h1>
<p>Também rodando no mesmo servidor Apache!</p>
```

---

### 🖥️ Passo 4: Configuração do Arquivo Hosts

Para acessar `site1.local` e `site2.local`, precisamos ensinar ao computador que esses nomes apontam para `localhost`.  

Edite o arquivo `hosts`:  

- **Windows:** `C:\Windows\System32\drivers\etc\hosts`  
- **Linux/macOS:** `/etc/hosts`  

Adicione no final:  

```
127.0.0.1 site1.local site2.local
```

*(No Windows, é necessário abrir o editor como Administrador para salvar o arquivo.)*

---

### 🚀 Passo 5: Testando no Navegador

Abra no navegador:  

- 👉 http://site1.local:8080  
- 👉 http://site2.local:8080  

Resultado esperado:  
- O primeiro site deve mostrar a página corporativa.  
- O segundo site deve mostrar o blog pessoal.  

---

### 🔍 Passo 6: Monitorando Logs

Veja os acessos em tempo real:  

```bash
docker-compose logs -f apache
```

Ou abra logs específicos:  

```bash
docker exec apache-server tail -f /usr/local/apache2/logs/site1.local_access.log
docker exec apache-server tail -f /usr/local/apache2/logs/site2.local_access.log
```

*(Os arquivos de log também ficam disponíveis diretamente na pasta `logs/` do projeto, fora do container.)*

---

## 📚 Conceitos Demonstrados

✅ Arquitetura modular do Apache (carregando apenas módulos necessários)  
✅ Virtual Hosts: hospedagem de múltiplos sites no mesmo servidor  
✅ Uso de volumes no Docker para configuração, sites e logs  
✅ Separação de logs por aplicação (site1 e site2)  
✅ Integração entre Docker e configuração manual do Apache  

---

## ⚠️ Erros Comuns

- **Porta 8080 já em uso** → altere a porta no `docker-compose.yml`.  
- **Site não abre** → confira se o arquivo `hosts` foi editado corretamente.  
- **Logs não aparecem** → verifique permissões da pasta `logs/`.  
- **Container não sobe** → confirme se o Docker está rodando com `docker ps`.  
- **DocumentRoot does not exist** → verifique se as pastas `site1.local/` e `site2.local/` foram criadas corretamente em `sites/`.  

---

## 🔮 Próximos Passos

Na próxima atividade vamos evoluir para **Nginx** e fazer um **comparativo com o Apache**.
