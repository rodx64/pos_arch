# 🛠️ Hands-On 05 - Parte 2: Nginx HA com Keepalived Avançado (VMs)

## 🎯 Objetivo

Implementar replicação de configuração usando **rsync**, configurar **health checks ativos e passivos**, 
simular falha no nó primário e validar **failover automático** com Keepalived entre **duas VMs Linux**
(Node1 e Node2) criadas no VirtualBox.

---

## 📦 Ambiente Utilizado

- **VirtualBox** (modo **Bridge**) → [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)  
- **ISO Ubuntu Server** → [Download Ubuntu](https://ubuntu.com/download/server)  
- **Duas VMs criadas no VirtualBox**:
  - node1 (MASTER)
  - node2 (BACKUP)

⚠️ Configure as duas VMs no **modo Bridge** para que fiquem na mesma rede local.

---

## 📂 Estrutura de Pastas

Crie a seguinte estrutura para guardar seus arquivos:

```bash
hands-on-05-ha-parte2/
├── node1/
│   ├── nginx.conf
│   └── index.html       # Página do Node1 (ATIVO)
├── node2/
│   ├── nginx.conf
│   └── index.html       # Página do Node2 (BACKUP)
├── keepalived-master/
│   └── keepalived.conf
├── keepalived-backup/
│   └── keepalived.conf
├── healthcheck.html
└── check_nginx_advanced.sh   # Script de verificação de saúde (usado por ambos)
```

---

## 🚀 Passos de Instalação

### 1) Instalar pacotes necessários
Execute em **ambas as VMs** (node1 e node2):

```bash
sudo apt update && sudo apt install -y nginx keepalived rsync curl
```

---

### 2) Páginas HTML

**Node1 (ATIVO)** → `/var/www/html/index.html`

```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Nginx Node 1 - ATIVO</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #e0ffe0; color: #28a745; text-align: center; padding-top: 50px; }
        h1 { color: #218838; }
        p { font-size: 1.2em; }
    </style>
</head>
<body>
    <h1>🚀 Nginx Node 1 - ATIVO!</h1>
    <p>Este é o servidor principal.</p>
</body>
</html>
EOF
```

**Node2 (BACKUP)** → `/var/www/html/index.html`

```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Nginx Node 2 - BACKUP</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #fff0e0; color: #ff8c00; text-align: center; padding-top: 50px; }
        h1 { color: #cc6600; }
        p { font-size: 1.2em; }
    </style>
</head>
<body>
    <h1>😴 Nginx Node 2 - BACKUP!</h1>
    <p>Este é o servidor de backup.</p>
</body>
</html>
EOF
```

**Healthcheck (igual nos dois nodes)** → `/var/www/html/healthcheck.html`

```bash
sudo tee /var/www/html/healthcheck.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Health OK</title></head>
<body><h1>Serviço Nginx Saudável!</h1></body>
</html>
EOF
```

---

### 3) Keepalived Configs

**Node1 (MASTER)** → `/etc/keepalived/keepalived.conf`
```bash
sudo tee /etc/keepalived/keepalived.conf > /dev/null <<'EOF'
vrrp_script check_nginx_advanced {          # Define um script de verificação customizado (health check)
    script "/usr/local/bin/check_nginx_advanced.sh"   # Caminho do script que será executado
    interval 2                                       # Intervalo entre execuções do script (em segundos)
    weight 50                                        # Peso que influencia a prioridade se o script falhar
    fall 2                                           # Quantas falhas consecutivas são necessárias para considerar DOWN
    rise 1                                           # Quantos sucessos consecutivos são necessários para considerar UP
}

vrrp_instance VI_1 {                   # Cria uma instância VRRP chamada "VI_1"
    state MASTER                       # Define o estado inicial deste nó (MASTER ou BACKUP)
    interface enp0s3                   # Interface de rede usada para VRRP (ex: enp0s3)
    virtual_router_id 51               # ID do roteador virtual (deve ser único na mesma rede)
    priority 101                       # Prioridade do nó (quanto maior, mais chance de ser MASTER)
    advert_int 1                       # Intervalo de anúncios VRRP (em segundos)

    authentication {                   # Configuração de autenticação VRRP
        auth_type PASS                 # Tipo de autenticação (senha simples)
        auth_pass mysecretpass         # Senha usada para validar os anúncios VRRP
    }

    virtual_ipaddress {                # Define o(s) IP(s) virtual(is) flutuante(s)
        192.168.15.200/24 dev enp0s3   # Endereço VIP que será migrado entre os nós
    }

    track_script {                     # Define os scripts a serem monitorados
        check_nginx_advanced           # Script de health check configurado acima
    }
}
EOF
```

**Node2 (BACKUP)** → `/etc/keepalived/keepalived.conf`

```bash
sudo tee /etc/keepalived/keepalived.conf > /dev/null <<'EOF'
vrrp_script check_nginx_advanced {              # Define o script de health check
    script "/usr/local/bin/check_nginx_advanced.sh"   # Script que será executado
    interval 2                                       # Executa o script a cada 2 segundos
    weight 50                                        # Peso que influencia na prioridade em caso de falha
    fall 2                                           # Precisa falhar 2 vezes seguidas para ser considerado DOWN
    rise 1                                           # Basta 1 sucesso para voltar a ser considerado UP
}

vrrp_instance VI_1 {                        # Instância VRRP (mesmo nome e ID do MASTER)
    state BACKUP                            # Este nó inicia como BACKUP (só assume se o MASTER falhar)
    interface enp0s3                        # Interface de rede usada para VRRP
    virtual_router_id 51                    # ID do roteador virtual (igual ao MASTER → precisam se "enxergar")
    priority 100                            # Prioridade menor que o MASTER (100 < 101), logo ele é BACKUP
    advert_int 1                            # Intervalo dos anúncios VRRP em segundos

    authentication {                        # Autenticação para validar mensagens VRRP
        auth_type PASS                      # Tipo de autenticação (senha simples)
        auth_pass mysecretpass              # Senha (deve ser igual ao MASTER)
    }

    virtual_ipaddress {                     # IP virtual compartilhado entre MASTER e BACKUP
        192.168.15.200/24 dev enp0s3        # VIP (mesmo que o MASTER)
    }

    track_script {                          # Scripts monitorados pelo VRRP
        check_nginx_advanced                # Usa o mesmo health check para decidir se pode assumir o VIP
    }
}

EOF
```

---

### 4) Script de Healthcheck Avançado

**Crie em ambas as VMs:** `/usr/local/bin/check_nginx_advanced.sh`

```bash
sudo tee /usr/local/bin/check_nginx_advanced.sh > /dev/null <<'EOF'
#!/bin/bash
# Script de verificação avançada do Nginx + serviço crítico

# 1) Health check HTTP no Nginx
# Faz uma requisição local para a página /healthcheck.html
# -s → modo silencioso
# -o /dev/null → descarta saída
# -w "%{http_code}" → captura apenas o código HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/healthcheck.html)

# Se o código de resposta não for 200, considera que o Nginx falhou
if [ "$HTTP_CODE" -ne "200" ]; then
  echo "Nginx não OK"
  exit 1            # Sinaliza falha para o Keepalived
fi

# 2) Health check passivo de um serviço crítico
# Verifica se existe um arquivo de controle (/tmp/FLAG_CRITICO_OK)
# Esse arquivo pode ser criado/atualizado por outro processo/serviço
if [ ! -f /tmp/FLAG_CRITICO_OK ]; then
  echo "Serviço crítico ausente"
  exit 1            # Se o arquivo não existir, considera falha
fi

# Se chegou até aqui → tudo OK
echo "Nginx OK + Serviço crítico OK"
exit 0              # Retorna sucesso (para o Keepalived continuar no ar)
EOF
```

Dar permissão:

```bash
sudo chmod +x /usr/local/bin/check_nginx_advanced.sh
sudo touch /tmp/FLAG_CRITICO_OK
```

---

## 🚀 Executando

Reinicie os serviços em **ambas as VMs**:

```bash
sudo systemctl restart nginx
sudo systemctl restart keepalived
```

Verifique o VIP no Master:

```bash
ip a | grep 192.168.15.200
```

Acesse no navegador:

```
http://192.168.15.200
```

---

## 🧪 Testes

### 1. Inicial
- **Comando:** acessar `http://192.168.15.200`  
- **Esperado:** página do **Node1 - ATIVO**.

### 2. Falha HTTP (Nginx parado)
```bash
sudo systemctl stop nginx
```
- **Esperado:** VIP vai para Node2 → mostra página "Node 2 - BACKUP".

### 3. Falha Serviço Crítico
```bash
#volta o node 1
sudo systemctl start nginx
#teste novamente, vai voltar master - node 1


rm /tmp/FLAG_CRITICO_OK
```
- **Esperado:** VIP vai para Node2, mesmo com Nginx ativo.

### 4. Failback
```bash
touch /tmp/FLAG_CRITICO_OK
```
- **Esperado:** VIP retorna ao Node1.

### 5. Replicação com rsync (conceitual)
Edite o index do Node1 e replique para Node2:

```bash
sudo nano /var/www/html/index.html
# Adicione por exemplo:
# <p>Última atualização: 02/09/2025 - 14h30</p>

rsync -avz /var/www/html/ aluno@192.168.15.176:/var/www/html/
```

> 🔑 Substitua `aluno@192.168.15.176` pelo usuário e IP real do Node2.

- **Esperado:** alteração também aparece no Node2.

---

📌 **Possível erro comum (Permissão negada):**  
Se aparecer algo como `failed to set times` ou `Permission denied`, significa que o diretório `/var/www/html` pertence ao root e seu usuário não tem permissão.  
Para resolver, no **Node2** rode:  

```bash
sudo chown -R aluno:aluno /var/www/html
sudo chmod -R u+rwX /var/www/html
```

> Assim o usuário terá permissão de escrita e o `rsync` vai funcionar corretamente.  

---

## 📚 O que você aprendeu

- Replicação de configuração entre nós (rsync).  
- Health check ativo (HTTP) + passivo (FLAG crítico).  
- Failover e failback automáticos com Keepalived em VMs.  

---

## 🔮 O que vem por aí (Parte 3)

1. Introdução a WAF: conceito, tipos e principais usos (dedicado vs integrado).  
2. Integração de WAF com balanceadores de carga (ModSecurity + OWASP CRS).  
3. Boas práticas de segurança: TLS, rate limiting, monitoramento e DR.  

**Hands-on:** Instalar ModSecurity no Nginx, habilitar OWASP CRS, criar regra personalizada, simular SQL Injection e validar bloqueio, aplicar rate limiting e checar métricas.
