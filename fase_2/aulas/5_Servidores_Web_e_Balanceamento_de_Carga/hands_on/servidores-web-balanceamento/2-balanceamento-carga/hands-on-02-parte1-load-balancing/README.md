# 🛠️ Hands-On 02 - Parte 1: Fundamentos e Configuração Básica de Load Balancing

## 🎯 Objetivo

Neste exercício você vai **configurar o Nginx como Load Balancer**,
entendendo:

1.  Por que o balanceamento de carga é importante para **escalabilidade e alta disponibilidade**.
2.  Como funciona o **método Round Robin** (padrão no Nginx).
3.  Como configurar um bloco **upstream** com múltiplos backends.
4.  Como integrar esse upstream em um **server block** para encaminhar requisições.
5.  (Opcional) Explorar os métodos **least_conn**, **ip_hash** e
    **weight**.

O objetivo é **visualizar na prática** a distribuição de requisições
entre múltiplos servidores backend.

------------------------------------------------------------------------

## 📂 Estrutura do Projeto

    hands-on-02-parte1-load-balancing/
    ├── docker-compose.yml
    ├── nginx/
    │   └── nginx.conf             # Configuração principal com upstream e server block
    ├── backend-server-1/
    │   └── html/index.html        # Página identificando "Backend 1"
    ├── backend-server-2/
    │   └── html/index.html        # Página identificando "Backend 2"
    ├── backend-server-3/
    │   └── html/index.html        # Página identificando "Backend 3"
    ├── backend-server-4/          #  Backend em Node criado só para testar o least_conn
    │   └── server.js
    │   └── Dockerfile
    └── README.md

------------------------------------------------------------------------

## 🚀 Como Executar

### Pré-requisitos

-   Docker instalado
-   Docker Compose instalado

------------------------------------------------------------------------

### 🔧 Passo 1: Subindo os Containers

1.  Vá para a pasta do projeto:

    ``` bash
    cd hands-on-02-parte1-load-balancing
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

### ⚙️ Passo 2: Configuração do Nginx

-   No arquivo `nginx/nginx.conf`, existe um bloco **upstream** listando
    os três backends.
-   O **server block** principal (porta 80) usa `proxy_pass` para
    encaminhar as requisições.
-   Um header adicional (**X-Backend-Server**) foi configurado para
    mostrar qual backend respondeu.

------------------------------------------------------------------------

### 🔄 Passo 3: Testando o Balanceamento (Round Robin)

-   Acesse no navegador: <http://localhost:8080>
-   Recarregue a página várias vezes e observe que a resposta alterna
    entre **Backend 1, 2 e 3**.
-   Verifique o header **X-Backend-Server**:
    -   **Navegador**: F12 → Aba *Network* → clique em uma requisição → *Headers*.
    -   **Logs no terminal**:

        ``` bash
        docker-compose logs -f nginx-balancer
        docker-compose logs -f backend-1
        docker-compose logs -f backend-2
        docker-compose logs -f backend-3
        ```

------------------------------------------------------------------------

### ⚖️ Passo 4: Explorando Outras Estratégias

-   **Weight**: Atribui mais peso a um backend (ex.: servidor mais
    potente).
-   **Least Connections**: Envia requisições para quem tem menos
    conexões ativas.
-   **IP Hash**: Sempre envia o mesmo cliente para o mesmo backend.

Para testar, edite `nginx.conf`, altere a diretiva do bloco upstream e
recarregue a configuração:

``` bash
docker-compose exec nginx-balancer nginx -s reload
```

------------------------------------------------------------------------

## 🧭 Como alternar e TESTAR cada estratégia

### 1) Round Robin (padrão)

**O que editar (no upstream)**
- **Mantenha** apenas as linhas `server ...` (sem `least_conn`,
`ip_hash` ou `weight`).

**Como TESTAR**

-   **Navegador (Console -- F12):**

    -   Primeiro, digite **allow pasting** no console e pressione Enter (para liberar colar).

    -   Depois, cole e execute:

        ``` js
        (async () => {
          const total = 20, contagem = {};
          for (let i = 1; i <= total; i++) {
            const r = await fetch("/", { cache: "no-store" });
            const body = await r.text();
            const header = r.headers.get("X-Backend-Server");
            const id = (body.match(/Backend\s*\d+/i)?.[0]) || header || "desconhecido";
            contagem[id] = (contagem[id] || 0) + 1;
            console.log(`${i} → ${id}`);
          }
          console.log("Resumo:"); console.table(contagem);
        })();
        ```

-   **Linux / macOS / WSL / Git Bash / VS Code (bash):**

    ``` bash
    for i in {1..10}; do curl -s http://localhost:8080/ | grep -E "Backend"; done
    ```

-   **Windows PowerShell:**

    ``` powershell
    1..10 | % { (Invoke-WebRequest http://localhost:8080/ -UseBasicParsing).Content } | Select-String "Backend"
    ```

**Esperado:** alternância **1 → 2 → 3** (ciclo).

------------------------------------------------------------------------

### 2) Least Connections

**O que editar (no upstream)**
- **Descomente** `least_conn;` 

**Como TESTAR (com concorrência)**

- **Navegador (Console — F12)** — cole este snippet para disparar 30 requisições **em paralelo** e ver quem respondeu (via header `X-Backend-Server`):
  ```js
  (async () => {
  const n = 50;
  const cont = {};
  
  const tasks = Array.from({ length: n }).map((_, i) =>
    fetch("/", { cache: "no-store" })
      .then((r) => {
        const who = r.headers.get("X-Backend-Server") || "desconhecido";
        cont[who] = (cont[who] || 0) + 1;
        console.log(i + 1, who);
        r.body?.cancel?.();
      })
      .catch((err) => console.error(`Erro ${i + 1}:`, err))
  );

  // Espera todas terminarem
  await Promise.allSettled(tasks);
  console.log("Resumo:", cont);
})();

  ```

- **Descobrindo IPs ↔ nomes dos containers** (para mostrar “quem é quem”):
  - **Windows (PowerShell — VS Code Terminal):**
    ```powershell
    $names=@("backend-app-1","backend-app-2","backend-app-3","backend-app-4","nginx-load-balancer"); foreach ($n in $names) { $ip = docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $n; "{0} -> {1}" -f $n,$ip }
    ```
  - **Linux / macOS / WSL / Git Bash:**
    ```bash
    for n in backend-app-1 backend-app-2 backend-app-3 backend-app-4 nginx-load-balancer; do
      ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$n")
      echo "$n -> $ip"
    done
    ```
  > Ajuste a lista (`backend-app-N`) conforme os **nomes dos seus containers** no `docker-compose.yml`.

**Esperado:** durante concorrência, o `least_conn` prioriza backends com **menos conexões ativas** naquele instante.

------------------------------------------------------------------------

### 3) IP Hash (sticky por IP)

**O que editar (no upstream)**\
- **Descomente** `ip_hash;` (mantenha as linhas `server ...`).
- **Não use** `weight` com `ip_hash`.

**Como TESTAR**
- Rode o loop várias vezes no mesmo terminal → sempre deve cair no **mesmo backend**.
- Abra **dois terminais** (ou dois navegadores) para simular clientes diferentes e comparar.

------------------------------------------------------------------------

### 4) Weight (pesos diferentes)

**O que editar (no upstream)**
- Adicione `weight=N` nas linhas server. Exemplo:
   ```nginx  
      upstream my_app_backends {
         server backend-app-1:80;
         server backend-app-2:80 weight=4;  # recebe mais requisições
         server backend-app-3:80;
      }
   ```

**Como TESTAR**
- Rode 20 requisições e veja a contagem:

  - **Linux / macOS / WSL / Git Bash:**

      ```bash   
      for i in {1..20}; do curl -sI http://localhost:8080/ | grep -i "X-Backend-Server"; done`
      ```

  - **Windows (PowerShell — VS Code Terminal):**    

      ```powershell
      1..20 | % { (Invoke-WebRequest http://localhost:8080/ -UseBasicParsing).Headers["X-Backend-Server"] }
      ```
**Esperado:** o backend com **maior weight** aparece **mais vezes**.

------------------------------------------------------------------------

## 🧪 Dicas de verificação

-   **Navegador (DevTools -- Console):** script JS resume a distribuição em **tabela**.
-   **Terminal:** loops em bash/PowerShell mostram o **BODY** ("Backend X") ou o **HEADER** `X-Backend-Server`.
------------------------------------------------------------------------

## 📚 Conceitos Demonstrados

✅ Importância do Load Balancing para disponibilidade e escalabilidade\
✅ Nginx como Load Balancer\
✅ Round Robin (método padrão)\
✅ Configuração de upstream e proxy_pass\
✅ Logs e headers para depuração\
✅ Estratégias alternativas de distribuição (least_conn, ip_hash,weight)
------------------------------------------------------------------------

## ⚠️ Erros Comuns

-   **Porta 80 já em uso** → altere a porta exposta no `docker-compose.yml`.
-   **Backend não responde** → verifique se o volume da pasta `html` foi montado corretamente.
-   **Configuração não aplicou** → use `nginx -s reload` dentro do container.
-   **Página não alterna** → confirme se todos os backends estão no bloco `upstream`.
------------------------------------------------------------------------

## 🔮 Próximos Passos

No próximo hands-on vamos explorar **health checks e failover no Nginx**, simulando falhas e validando a resiliência do balanceador.
