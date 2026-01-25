# 🛠️ Hands-On 05: Nginx HA Ativo-Passivo com Keepalived (VirtualBox + Linux)

## 🎯 Objetivo
Configurar um cluster de **Alta Disponibilidade (HA)** com **Nginx + Keepalived**, simulando ambiente **ativo-passivo** usando **duas VMs Linux no VirtualBox**.  
Um IP Virtual (VIP) será compartilhado entre os nós para garantir failover automático.

---

## 📦 Ambiente Utilizado
- **VirtualBox** (modo **Bridge**) → [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- **ISO Ubuntu Server** → [Download Ubuntu](https://ubuntu.com/download/server)
- **Duas VMs criadas no VirtualBox**:
  - node1 (MASTER)
  - node2 (BACKUP)

> ⚠️ Configure as duas VMs no **modo Bridge** para que fiquem na mesma rede local.

---

## 📂 Estrutura do Projeto
```
hands-on-05-ha-parte1-nginx-ha/
├── node1/
│   ├── nginx.conf
│   └── index.html   # Página do Node1 (ATIVO)
├── node2/
│   ├── nginx.conf
│   └── index.html   # Página do Node2 (BACKUP)
├── keepalived-master/
│   └── keepalived.conf
├── keepalived-backup/
│   └── keepalived.conf
└── check_nginx.sh   # Script de verificação de saúde (usado por ambos)
```

---

## 🚀 Passos de Instalação

### 1) Instalar pacotes necessários
Execute em **ambas as VMs** (node1 e node2):
```bash
sudo apt update && sudo apt install -y nginx keepalived curl
```

---

### 2) Criar páginas HTML personalizadas

#### Node1 (MASTER)
```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Node 1 - ATIVO</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #e0ffe0; color: #28a745; text-align: center; padding-top: 50px; }
        h1 { color: #218838; }
        p { font-size: 1.2em; }
        .node-info { margin-top: 30px; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🚀 Nginx Node 1 - ATIVO!</h1>
    <p>Este é o servidor Nginx principal.</p>
    <div class="node-info">IP Virtual: <span id="vip"></span></div>
    <div class="node-info">Servindo em: <span id="hostname"></span></div>
    <script>
        document.getElementById('vip').innerText = window.location.hostname;
        document.getElementById('hostname').innerText = window.location.origin;
    </script>
</body>
</html>
EOF
```

#### Node2 (BACKUP)
```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Node 2 - BACKUP</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #fff0e0; color: #ff8c00; text-align: center; padding-top: 50px; }
        h1 { color: #cc6600; }
        p { font-size: 1.2em; }
        .node-info { margin-top: 30px; font-weight: bold; }
    </style>
</head>
<body>
    <h1>😴 Nginx Node 2 - BACKUP (Pronto para assumir!)</h1>
    <p>Este é o servidor Nginx de backup.</p>
    <div class="node-info">IP Virtual: <span id="vip"></span></div>
    <div class="node-info">Servindo em: <span id="hostname"></span></div>
    <script>
        document.getElementById('vip').innerText = window.location.hostname;
        document.getElementById('hostname').innerText = window.location.origin;
    </script>
</body>
</html>
EOF
```

Reinicie o serviço Nginx:
```bash
sudo systemctl restart nginx
```

---

### 3) Script de saúde do Nginx (usado pelo Keepalived)
Crie em **ambas as VMs**:
```bash
sudo tee /usr/local/bin/check_nginx.sh > /dev/null <<'EOF'
#!/bin/bash
# Script de verificação de saúde do Nginx
# Precisa estar acessível para o Keepalived e ser executável.

# Verifica se o Nginx responde em localhost
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1)

if [ "$HTTP_CODE" -eq "200" ]; then
    echo "Nginx está OK (HTTP 200)"
    exit 0 # Sucesso
else
    echo "Nginx está DOWN (HTTP Code: $HTTP_CODE)"
    exit 1 # Falha
fi
EOF

sudo chmod +x /usr/local/bin/check_nginx.sh
```

---

### 4) Configuração do Keepalived

#### Node1 (MASTER)
```bash
sudo tee /etc/keepalived/keepalived.conf > /dev/null <<'EOF'
# Configuração Keepalived para o nó MASTER

vrrp_script check_nginx {
    script "/usr/local/bin/check_nginx.sh" # Script para verificar saúde do Nginx
    interval 2  # Executa a cada 2 segundos
    weight 50   # Adiciona 50 pontos se sucesso
    fall 2      # Se falhar 2 vezes, remove 50 pontos
    rise 1      # Se tiver sucesso 1 vez, adiciona 50 pontos
}

vrrp_instance VI_1 {
    state MASTER              # Este nó começa como MASTER
    interface enp0s3          # Interface de rede (ajustar se necessário)
    virtual_router_id 51      # ID único do cluster VRRP
    priority 101              # Maior prioridade para MASTER
    advert_int 1              # Frequência dos anúncios VRRP

    authentication {
        auth_type PASS
        auth_pass mysecret    # Senha de autenticação (mesma nos dois nós)
    }

    virtual_ipaddress {
        192.168.15.200/24 dev enp0s3  # IP Virtual (VIP)
    }

    track_script {
        check_nginx           # Monitora a saúde do Nginx
    }
}
EOF
```

#### Node2 (BACKUP)
```bash
sudo tee /etc/keepalived/keepalived.conf > /dev/null <<'EOF'
# Configuração Keepalived para o nó BACKUP

vrrp_script check_nginx {
    script "/usr/local/bin/check_nginx.sh"
    interval 2
    weight 50
    fall 2
    rise 1
}

vrrp_instance VI_1 {
    state BACKUP              # Este nó começa como BACKUP
    interface enp0s3
    virtual_router_id 51
    priority 100              # Menor que o MASTER
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass mysecret
    }

    virtual_ipaddress {
        192.168.15.200/24 dev enp0s3
    }

    track_script {
        check_nginx
    }
}
EOF
```

---

### 5) Ativar Keepalived
Em ambas as VMs:
```bash
sudo systemctl enable keepalived
sudo systemctl restart keepalived
sudo systemctl status keepalived
```

---

## 🔍 Testes

### Verificar VIP no MASTER
```bash
ip a | grep 192.168.15.200
```

### Testar acesso via VIP
```bash
curl http://192.168.15.200
```

### Simular Failover
```bash
sudo systemctl stop nginx
```

Resultado esperado: o **VIP muda para o BACKUP** e a página mostrada será a do Node2.

### Restaurar
```bash
sudo systemctl start nginx
```

VIP volta para o Node1 (MASTER).

---

## 📚 O que você aprendeu
- Como usar **Keepalived** para gerenciar um VIP.  
- Como configurar **Nginx HA ativo-passivo**.  
- Como os scripts de saúde impactam a decisão de failover.  
- Como simular **failover e failback** em laboratório com VirtualBox.
