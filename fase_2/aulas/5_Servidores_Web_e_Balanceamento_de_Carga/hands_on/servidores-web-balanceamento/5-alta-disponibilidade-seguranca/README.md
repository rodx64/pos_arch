# Alta Disponibilidade (HA) e Segurança (Aula 5)

Este diretório contém os exemplos práticos (hands-on) da **Aula 5 – Alta Disponibilidade (HA) e Segurança**, organizados por vídeo para facilitar o acompanhamento durante as videoaulas.

---

## 🛠️ Pré-requisitos

Antes de iniciar os hands-on, certifique-se de ter instalado:

- **Docker** + **Docker Compose** → [Instalação](https://docs.docker.com/get-docker/)  
- **VirtualBox** (apenas para a Parte 2, onde utilizaremos VMs) → [Download](https://www.virtualbox.org/wiki/Downloads)  
- **Ubuntu Server ISO** (para os testes com Keepalived na Parte 2) → [Download](https://ubuntu.com/download/server)  
- **Git** → [Download](https://git-scm.com/downloads)  
- **Ferramentas de teste**:  
  - `curl` → [Documentação](https://curl.se/docs/install.html)  

✅ Verifique a instalação:
```bash
docker --version
docker compose version
git --version
curl --version
```

---

## 🚀 Como Usar Este Repositório

### 1. Clone o repositório
```bash
cd servidores-web-balanceamento-teste/5-alta-disponibilidade-seguranca
```

### 2. Navegue pelas pastas dos vídeos
Cada pasta corresponde a uma parte da aula e contém:
- `README.md` com instruções específicas  
- Arquivos de configuração (`nginx.conf`, `keepalived.conf`, `docker-compose.yml`, scripts de health check)  
- Pastas auxiliares (`node1`, `node2`, `api`, `nginx`)  

### 3. Siga a sequência dos vídeos
📹 Parte 1: [Fundamentos e Arquiteturas de HA](./hands-on-05-ha-parte1-nginx-ha/README.md)  
📹 Parte 2: [Replicação, Failover e Testes de Resiliência (VMs)](./hands-on-05-ha-parte2/README.md)  
📹 Parte 3: [Segurança com WAF e Boas Práticas no Nginx](./hands-on-05-ha-parte3/README.md)  

---

## 🎯 Objetivos de Aprendizagem
Ao final desta aula você será capaz de:

✅ Entender os fundamentos de **Alta Disponibilidade (HA)** e como projetar arquiteturas resilientes  
✅ Configurar um **cluster ativo-passivo de Nginx com Keepalived** para IP virtual  
✅ Implementar **replicação de configuração e health checks** em **VMs** para failover automático  
✅ Instalar e configurar um **WAF (ModSecurity) com OWASP Core Rule Set (CRS)** no Nginx  
✅ Criar **regras personalizadas de segurança** e validar bloqueios (ex: SQL Injection)  
✅ Aplicar **Rate Limiting** e analisar métricas de segurança nos logs  

---

## 📊 Tópicos Abordados
| Parte | Tópicos | Hands-on |
|-------|---------|----------|
| **1** | Fundamentos de HA, arquiteturas resilientes, Keepalived | Configuração inicial de dois Nginx em cluster ativo-passivo com Docker + Keepalived |
| **2** | Replicação, failover, health checks, testes de resiliência | Implementar rsync, configurar health checks ativos/passivos, simular falha no nó primário e validar failover em **duas VMs (VirtualBox)** |
| **3** | Segurança em servidores web, WAF, boas práticas | Instalar ModSecurity, habilitar OWASP CRS, criar regra personalizada, simular SQLi, aplicar Rate Limiting e analisar logs |

---

## 📚 Referências
- [Keepalived Official Documentation](https://keepalived.readthedocs.io/)  
- [Nginx Documentation](https://nginx.org/en/docs/)  
- [ModSecurity Handbook](https://github.com/SpiderLabs/ModSecurity/wiki)  
- [OWASP Core Rule Set](https://coreruleset.org/)  
- [High Availability Concepts – RedHat](https://access.redhat.com/articles/3650671)  
