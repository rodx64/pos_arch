# Balanceamento de Carga na Prática (Aula 2)

Este diretório contém os exemplos práticos (hands-on) da **Aula 2 – Balanceamento de Carga na Prática**, organizados por vídeo para facilitar o acompanhamento durante as videoaulas.

---

## 🛠️ Pré-requisitos

Antes de iniciar os hands-on, certifique-se de ter instalado:

- **Docker** (20.10 ou superior) → [Instalação](https://docs.docker.com/get-docker/)  
- **Docker Compose** (v2.0 ou superior) → [Instalação](https://docs.docker.com/compose/install/)  
- **Git** → [Download](https://git-scm.com/downloads)  
- **Ferramentas de teste**:  
  - `curl` → [Documentação](https://curl.se/docs/install.html)  
  - `Apache Bench (ab)` → parte do pacote `apache2-utils` ([Referência](https://httpd.apache.org/docs/2.4/programs/ab.html))

✅ Verifique a instalação:
```bash
docker --version
docker compose version
git --version
curl --version
ab -V
```

---

## 🚀 Como Usar Este Repositório

### 1. Clone o repositório
```bash
cd balanceamento-carga/2-Balanceamento%20de%20Carga%20na%20Prática
```

### 2. Navegue pelas pastas dos vídeos
Cada pasta corresponde a um vídeo da aula e contém:
- `README.md` com instruções específicas  
- `docker-compose.yml`  
- Arquivos de configuração  
- Exemplos e comandos de teste  

### 3. Siga a sequência dos vídeos
📹 Vídeo 1: [1-Fundamentos e Configuração Básica de Load Balancing](./hands-on-02-parte1-load-balancing/README.md)  
📹 Vídeo 2: [2-Health Checks e Failover no Nginx](./hands-on-02-parte2-failover/README.md)  
📹 Vídeo 3: [3-Monitoramento, Testes de Carga e Troubleshootingg](./hands-on-02-parte3-monitoring-testing-troubleshooting/README.md)  

---

## 🎯 Objetivos de Aprendizagem
Ao final desta aula você será capaz de:

✅ Entender a importância do **Load Balancing** para escalabilidade e alta disponibilidade  
✅ Configurar diferentes **métodos de balanceamento no Nginx** (Round Robin, Least Connections, IP Hash)  
✅ Implementar **health checks** ativos e passivos  
✅ Validar **failover** em cenários de falha  
✅ Realizar **monitoramento de tráfego e métricas** no Nginx  
✅ Executar **testes de carga com Apache Bench**  
✅ Corrigir problemas comuns com **troubleshooting prático**  

---

## 📊 Tópicos Abordados
| Vídeo | Tópicos | Hands-on |
|-------|---------|----------|
| **1** | Por que usar Load Balancing, Métodos no Nginx, Configuração de Upstream | Configuração de upstream no Nginx com múltiplos backends em Docker |
| **2** | Health Checks ativos/passivos, Failover e Alta Disponibilidade | Health checks no Nginx, simulação de falhas e validação de failover |
| **3** | Monitoramento de tráfego, Testes de carga, Troubleshooting | Coleta de métricas, Apache Bench, análise de logs, correção de configs |

---

## 📚 Referências
- [Nginx Documentation](https://nginx.org/en/docs/)  
- [Nginx Load Balancing](https://nginx.org/en/docs/http/load_balancing.html)  
- [Apache Bench Reference](https://httpd.apache.org/docs/2.4/programs/ab.html)  
