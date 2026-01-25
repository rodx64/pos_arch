# Servidores Web com Nginx e Apache

Este repositório contém todos os exemplos práticos (hands-on) da **Aula 1 – Servidores Web com Nginx e Apache**, organizados por vídeo para facilitar o acompanhamento durante as videoaulas.


## 🛠️ Pré-requisitos

Antes de iniciar os hands-on, certifique-se de ter os seguintes softwares instalados:

- **Docker** (versão 20.10 ou superior)  
  [Guia Oficial de Instalação](https://docs.docker.com/get-docker/)

- **Docker Compose** (versão 2.0 ou superior – já incluso no Docker Desktop e em distribuições recentes do Docker)  
  [Documentação Oficial](https://docs.docker.com/compose/install/)

- **Git**  
  [Instalação Oficial](https://git-scm.com/downloads)

- **Ferramentas de teste:**  
  - `curl` – [Documentação](https://curl.se/docs/install.html)  
  - `Apache Bench (ab)` – parte do pacote `apache2-utils` ou similar ([Referência](https://httpd.apache.org/docs/2.4/programs/ab.html))

### ✅ Verificação da Instalação
```bash
docker --version
docker compose version
git --version
curl --version
ab -V
```
## 🚀 Como Usar Este Repositório

### 1. Clone o Repositório
```bash
cd servidores-web-balanceamento
```

### 2. Navegue pelas Pastas dos Vídeos
Cada pasta corresponde a um vídeo da aula e contém:

- `README.md` com instruções específicas  
- `docker-compose.yml` para subir os serviços  
- Arquivos de configuração personalizados  
- Exemplos de código e comandos  

### 3. Siga a Sequência dos Vídeos
📹 Vídeo 1: [1-Fundamentos e Apache na Prática](./1-Fundamentos%20e%20Apache%20na%20Prática/README.md)  
📹 Vídeo 2: [2-Nginx e Comparativo com Apache](./2-Nginx%20e%20Comparativo%20com%20Apache/README.md)  
📹 Vídeo 3: [3-Configurações Avançadas e Integração Nginx + Apache](./3-Configurações%20Avançadas%20e%20Integração%20Nginx%20+%20Apache/README.md)  

## 🎯 Objetivos de Aprendizagem
Ao completar todos os exercícios, você será capaz de:

✅ Configurar servidores Apache e Nginx via Docker  
✅ Implementar Forward Proxy e Reverse Proxy  
✅ Comparar performance entre Apache e Nginx  
✅ Integrar Nginx + Apache em arquiteturas híbridas  

## 📊 Tópicos Abordados
| Vídeo | Tópicos | Hands-on |
|-------|---------|----------|
| **1** | Servidor Web, Forward/Reverse Proxy, Apache | Apache básico, VirtualHost, Proxies |
| **2** | Nginx, Comparativo Apache vs Nginx | Nginx básico, Benchmarks, Performance |
| **3** | Configurações Avançadas, Integração | Cache, SSL, mod_rewrite, Stack completa |

## 📚 Referências Adicionais

[Documentação Oficial] – Apache HTTP Server – Apache Software Foundation – 2024  
https://httpd.apache.org/docs/2.4/

[Documentação Oficial] – Apache Modules – Apache Software Foundation – 2024  
https://httpd.apache.org/docs/2.4/mod/

[Documentação Oficial] – Apache Virtual Host – Apache Software Foundation – 2024  
https://httpd.apache.org/docs/2.4/vhosts/

[Documentação Oficial] – Nginx Documentation – Nginx Inc. – 2024  
https://nginx.org/en/docs/

[Documentação Oficial] – Nginx Modules Reference – Nginx Inc. – 2024  
https://nginx.org/en/docs/http/

[Documentação Oficial] – Nginx Beginner's Guide – Nginx Inc. – 2024  
https://nginx.org/en/docs/beginners_guide.html
