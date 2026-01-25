# 🛠️ Hands-On 02 - Parte 2: Health Checks e Failover no Nginx

## 🎯 Objetivo

Neste exercício você vai **configurar Health Checks Passivos e Failover
no Nginx**, entendendo:

1.  Como usar `max_fails` e `fail_timeout` para detectar backends
    indisponíveis.\
2.  Como configurar um **servidor de backup** no bloco `upstream`.\
3.  Como simular falha de backends primários e observar o **failover
    automático**.\
4.  Como o Nginx reintegra um backend recuperado após a falha.

O objetivo é **visualizar na prática** como o Nginx garante alta
disponibilidade.

------------------------------------------------------------------------

## 📂 Estrutura do Projeto

    hands-on-02-parte2-failover/
    ├── docker-compose.yml
    ├── nginx/
    │   └── nginx.conf                  # Configuração principal com upstream, failover e backup
    ├── backend-server-1/
    │   └── html/index.html             # Página identificando "Backend 1"
    ├── backend-server-2/
    │   └── html/index.html             # Página identificando "Backend 2"
    ├── backend-server-backup/
    │   └── html/index.html             # Página identificando "Servidor de Backup"
    └── README.md

------------------------------------------------------------------------

## 🚀 Como Executar

### Pré-requisitos

-   Docker instalado\
-   Docker Compose instalado

------------------------------------------------------------------------

### 🔧 Passo 1: Subindo os Containers

1.  Vá para a pasta do projeto:

    ``` bash
    cd hands-on-02-parte2-failover
    ```

2.  Suba os containers:

    ``` bash
    docker-compose up -d
    ```

3.  Verifique se estão rodando:

    ``` bash
    docker-compose ps
    ```

------------------------------------------------------------------------

### ⚙️ Passo 2: Testando Failover

-   Abra no navegador:\
    👉 <http://localhost:8080>

-   Por padrão, o Nginx fará Round Robin entre **Backend 1** e **Backend
    2**.\

-   O header `X-Backend-Server` foi configurado para indicar qual
    backend respondeu.

------------------------------------------------------------------------

### 🔄 Passo 3: Simulando Falhas

**Parar um backend:**

``` bash
docker-compose stop backend-1
```

👉 Recarregue <http://localhost:8080> várias vezes.\
**Esperado:** apenas o **Backend 2** responderá.

------------------------------------------------------------------------

**Parar todos os backends primários:**

``` bash
docker-compose stop backend-1
docker-compose stop backend-2
```

👉 Recarregue <http://localhost:8080>.\
**Esperado:** o Nginx usará o **Servidor de Backup**.

------------------------------------------------------------------------

**Recuperar os backends:**

``` bash
docker-compose start backend-1
docker-compose start backend-2
```

👉 Após alguns segundos (`fail_timeout=5s`), o Nginx volta a usar os
backends primários.

------------------------------------------------------------------------

### 📜 Comandos Úteis

``` bash
# Subir os serviços
docker-compose up -d

# Recarregar configuração do Nginx
docker-compose exec nginx-load-balancer-failover nginx -s reload

# Ver logs do Nginx
docker-compose logs -f nginx-load-balancer-failover

# Ver logs de um backend específico
docker-compose logs -f backend-app-1

# Derrubar tudo
docker-compose down
```

------------------------------------------------------------------------

## 📚 Conceitos Demonstrados

✅ Health Checks Passivos (`max_fails`, `fail_timeout`)\
✅ Failover Automático de Backends\
✅ Uso da diretiva `backup` no bloco `upstream`\
✅ Continuidade de serviço mesmo com falhas\
✅ Recuperação automática de servidores

------------------------------------------------------------------------

## ⚠️ Erros Comuns

-   **Porta 8080 em uso** → altere a porta exposta no
    `docker-compose.yml`.\
-   **Página não muda de backend** → verifique se
    `add_header X-Backend-Server $upstream_addr;` está no `nginx.conf`.\
-   **Falha não reconhecida** → confirme os parâmetros `max_fails` e
    `fail_timeout`.

------------------------------------------------------------------------

## 🔮 Próximos Passos

No próximo hands-on, vamos explorar **Monitoramento de tráfego e métricas no Nginx**,  
realizar **testes de carga com Apache Bench** e praticar **troubleshooting de configurações de balanceamento**.
