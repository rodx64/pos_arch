# 🛠️ Hands-On 02: Proxy Direto e Proxy Reverso

## 🎯 Objetivo

Neste exercício você vai **configurar dois tipos de proxy**:  
1. **Proxy Direto (Forward Proxy)** usando **Squid** para **bloquear acesso a redes sociais**.  
2. **Proxy Reverso (Reverse Proxy)** usando **Nginx** para **balancear carga entre múltiplos servidores**.  

O objetivo é **visualizar na prática** os conceitos apresentados em aula sobre **controle de tráfego de saída** (funcionários → internet) e **roteamento de entrada** (usuários → servidores).  

---

## 📂 Estrutura do Projeto

```
hands-on-02-proxy/
├── proxy-direto/
│   ├── squid-config/
│   │   └── squid.conf
│   └── docker-compose.yml
├── proxy-reverso/
│   ├── nginx.conf
│   └── docker-compose.yml
└── README.md
```

---

## 🚀 Como Executar

### Pré-requisitos

- Docker instalado  
- Docker Compose instalado  

---

### 🔧 Proxy Direto (Forward Proxy com Squid)

1. Vá para a pasta:

   ```bash
   cd proxy-direto
   ```

2. Suba o container:

   ```bash
   docker-compose up -d
   docker logs proxy-squid
   ```

   ⚠️ **Possível erro no Windows (Docker Desktop)**  
   Se ao rodar `docker-compose up -d` você receber erros como:  
   ```
   error during connect: Post "http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.51/containers/create?...": EOF
   ```
   Isso significa que o **Docker não conseguiu acessar as pastas do projeto**.  

   ✅ **Solução:**  
   - Abra o **Docker Desktop**  
   - Vá em **Settings → Resources → File Sharing**  
   - Adicione a pasta do projeto 
   - Clique em **Apply & Restart**  
   - Rode novamente `docker-compose up -d`  

3. Configure o navegador para usar **localhost:3128** como proxy.  

   **Windows 10/11**  
   - Vá em **Iniciar → Configurações → Rede e Internet → Proxy**.  
   - Ative a opção **Usar um servidor proxy manual**.  
   - Em **Endereço**, digite: `localhost`  
   - Em **Porta**, digite: `3128`  
   - Salve e feche.  

   **macOS**  
   - Vá em **Preferências do Sistema → Rede**.  
   - Selecione a sua conexão ativa (**Wi-Fi** ou **Ethernet**) e clique em **Avançado**.  
   - Vá até a aba **Proxies**.  
   - Marque **Proxy Web (HTTP)** e **Proxy Seguro (HTTPS)**.  
   - No campo **Servidor**, digite: `localhost` e em **Porta**: `3128`.  
   - Clique em **OK → Aplicar**.  

   **Linux (Ubuntu / Debian)**  
   - Vá em **Configurações → Rede → Proxy de Rede**.  
   - Selecione a opção **Manual**.  
   - No campo **HTTP** e **HTTPS**, coloque:  
     - **Host:** `localhost`  
     - **Porta:** `3128`  
   - Salve e feche.  

   ⚠️ **Observação:** cada sistema pode ter pequenas variações de menu.  
   Se não encontrar as opções acima, pesquise:  
   👉 *"Como configurar proxy no [nome do seu sistema]"*  

4. Teste os acessos:

   - ❌ http://facebook.com → Bloqueado  
   - ❌ http://instagram.com → Bloqueado  
   - ✅ http://google.com → Permitido  
   - ✅ http://github.com → Permitido  

5. Veja os logs em tempo real:

   ```bash
   docker logs -f proxy-squid
   ```

---

### ⚖️ Proxy Reverso (Reverse Proxy com Nginx)

1. Vá para a pasta:

   ```bash
   cd proxy-reverso
   ```

2. Suba os containers:

   ```bash
   docker-compose up -d
   ```

   ⚠️ **Possível erro no Windows (Docker Desktop)**  
   Se ao rodar `docker-compose up -d` você receber erros como:  
   ```
   error during connect: Post "http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.51/containers/create?...": EOF
   ```
   Isso significa que o **Docker não conseguiu acessar as pastas do projeto**.  

   ✅ **Solução:**  
   - Abra o **Docker Desktop**  
   - Vá em **Settings → Resources → File Sharing**  
   - Adicione a pasta do projeto 
   - Clique em **Apply & Restart**  
   - Rode novamente `docker-compose up -d`  

3. Teste múltiplas requisições:  

   **Linux / macOS (bash/zsh):**
   ```bash
   for i in {1..6}; do
     curl -s http://localhost
     echo "---"
     sleep 1
   done
   ```

   **Windows (PowerShell no VS Code):**
   ```powershell
   for ($i=1; $i -le 6; $i++) {
     curl http://localhost
     Write-Output "---"
     Start-Sleep -Seconds 1
   }
   ```

   **Windows (CMD):**
   ```cmd
   for /l %i in (1,1,6) do (
     curl http://localhost
     echo ---
     timeout /t 1 >nul
   )
   ```

   Resultado esperado: alternância entre  

   - `Servidor 1 - Instância A`  
   - `Servidor 2 - Instância B`  
   - `Servidor 3 - Instância C`  

---

## 📚 Conceitos Demonstrados

✅ Proxy Direto: controle de tráfego de saída (ex: funcionários → internet)  
✅ Proxy Reverso: controle de tráfego de entrada (usuários → servidores)  
✅ Bloqueio de domínios no Squid  
✅ Balanceamento de carga com Nginx (round-robin)  
✅ Configuração via Docker Compose  

---

## ⚠️ Erros Comuns

- **Porta 3128 já em uso** → Ajuste a porta no `docker-compose.yml` do Squid.  
- **Página não carrega no navegador** → Verifique se o proxy está configurado corretamente.  
- **Containers não sobem** → Confira se o Docker está rodando (`docker ps`).  

---

## 🔮 Próximos Passos

Na próxima atividade vamos explorar o **Apache HTTP Server**, entendendo:  
4. **Visão geral do Apache** (arquitetura, módulos, configuração).  
5. **Hands-on: Apache com Docker Compose**, configuração básica e um **Virtual Host simples**.
