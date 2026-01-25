# 🛠️ Hands-On 02 - Parte 3: Monitoramento, Testes de Carga e Troubleshooting no Nginx

## 🎯 Objetivo
Neste exercício você vai **habilitar métricas no Nginx, realizar testes de carga e aplicar troubleshooting**, entendendo:

1. Como expor métricas com `stub_status`.  
2. Como rodar **Apache Bench (ab)** dentro de um **container dedicado**.  
3. Como analisar logs do Nginx e dos backends.  
4. Como simular falhas de backends e validar o failover automático.  

---

## 📂 Estrutura do Projeto

```
hands-on-02-parte3-monitoring-testing-troubleshooting/
├── docker-compose.yml              # Mesmo da Parte 2, agora com container "ab"
├── nginx/
│   └── nginx.conf                  # Atualizado com stub_status
├── backend-server-1/
│   └── html/index.html
├── backend-server-2/
│   └── html/index.html
├── backend-server-backup/
│   └── html/index.html
└── README.md
```

---

## 🚀 Como Executar

### Pré-requisitos
- Docker e Docker Compose instalados  
- Curl instalado no host  

---

### 🔧 Passo 1: Subindo os Containers

1. Vá para a pasta do projeto:
   ```bash
   cd hands-on-02-parte3-monitoring-testing-troubleshooting
   ```

2. Suba os containers:
   ```bash
   docker-compose up -d
   ```

3. Recarregue o Nginx para garantir o `stub_status`:
   ```bash
   docker-compose exec nginx-balancer nginx -s reload
   ```

---

### 📊 Passo 2: Monitoramento com stub_status

Consultar métricas em tempo real:

```bash
curl http://localhost:8080/nginx_status
```

Principais campos:  
- **Active connections** → conexões abertas  
- **Accepts / Handled / Requests** → contadores de tráfego  
- **Reading** → lendo cabeçalhos  
- **Writing** → enviando respostas  
- **Waiting** → conexões keep-alive  

---

### 📈 Passo 3: Testes de Carga com Apache Bench (Container)

Para rodar o `ab` dentro de um container (portável para Windows):

Teste básico (100 requisições, 10 concorrentes):  
```bash
docker-compose exec ab-tester ab  -n 100 -c 10 http://nginx-balancer/
```

Teste de estresse (5000 requisições, 50 concorrentes):  
```bash
docker-compose exec ab-tester ab -n 5000 -c 50 http://nginx-balancer/
```

⚠️ Note que usamos `http://nginx-balancer/` pois o `ab` roda dentro da rede Docker e acessa o serviço pelo nome definido no `docker-compose.yml`.

Métricas importantes:  
- **Requests per second (RPS)** → capacidade  
- **Time per request (TPR)** → velocidade  
- **Percentis (90%, 95%)** → experiência da maioria  

---

### 🔍 Passo 4: Troubleshooting

Ver logs do Nginx:  
```bash
docker-compose logs -f nginx-balancer
```

Ver logs de um backend específico:  
```bash
docker-compose logs -f backend-1
```

Simular falha de backend:  
```bash
docker-compose stop backend-1
```

Simular recuperação:  
```bash
docker-compose start backend-1
```

---

### 📜 Comandos Úteis

```bash
# Subir os serviços
docker-compose up -d

# Recarregar config do Nginx
docker-compose exec nginx-balancer nginx -s reload

# Consultar status
curl http://localhost:8080/nginx_status

# Teste de carga com container ab
docker-compose run --rm ab ab -n 1000 -c 10 http://nginx-balancer/

# Derrubar tudo
docker-compose down
```

---

## 📚 Conceitos Demonstrados

✅ Monitoramento básico (`stub_status`)  
✅ Testes de carga com Apache Bench (`ab`) via container  
✅ Análise de logs do Nginx e dos backends  
✅ Troubleshooting de falhas em backends  
✅ Alta disponibilidade na prática  

---

## 🔮 Próximos Passos

Na próxima parte, vamos dar início à **Aula 3 – Gerenciamento de Tráfego no Kubernetes com Nginx Ingress Controller**,  
onde veremos como **configurar e gerenciar tráfego no Kubernetes**, aplicando:  

- Roteamento por **host** e **path**  
- Implementação de **HTTPS com cert-manager**  
- **Boas práticas de segurança** para ambientes produtivos  
