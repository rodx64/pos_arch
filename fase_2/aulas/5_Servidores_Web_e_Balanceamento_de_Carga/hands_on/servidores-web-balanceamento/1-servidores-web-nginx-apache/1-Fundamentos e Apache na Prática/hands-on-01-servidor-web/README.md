# 🛠️ Hands-On 01: Seu Primeiro Servidor Web

## 🎯 Objetivo
Neste exercício você vai **subir seu primeiro servidor web** usando **Apache HTTP Server** dentro de um container Docker.  
O objetivo é **visualizar na prática** os conceitos apresentados em aula sobre **arquitetura cliente-servidor** e **entrega de arquivos estáticos** (HTML e CSS).

---

## 📂 Estrutura do Projeto
```
hands-on-01-servidor-web/
├── docker-compose.yml
├── html/
│   ├── index.html
│   ├── sobre.html
│   └── css/
│       └── style.css
└── README.md
```

---

## 🚀 Como Executar

### Pré-requisitos
- Docker instalado  
- Docker Compose instalado  

### Passos
1. Clone ou baixe este diretório
2. Navegue até a pasta do projeto:
   ```bash
   cd hands-on-01-servidor-web
   ```
3. Suba o servidor:
   ```bash
   docker-compose up -d
   ```
4. Abra no navegador:
   - 🌐 Página principal: [http://localhost:8080](http://localhost:8080)  
   - 📖 Página Sobre: [http://localhost:8080/sobre.html](http://localhost:8080/sobre.html)

---

## 🔧 Comandos Úteis

### Subir e testar
```bash
docker-compose up -d
docker-compose ps
```

### Ver logs em tempo real
```bash
docker-compose logs -f
```

### Encerrar servidor
```bash
docker-compose down
```

---

## 📚 Conceitos Demonstrados
✅ Arquitetura Cliente-Servidor  
✅ Protocolo HTTP  
✅ Mapeamento de Portas (8080 → 80)  
✅ Volumes no Docker  
✅ Servindo Arquivos Estáticos (HTML, CSS)  

---

## ⚠️ Erros Comuns
- **Porta 8080 já em uso** → Feche o processo que está usando a porta ou troque no `docker-compose.yml`.  
- **Docker não encontrado** → Verifique se o Docker está instalado e rodando (`docker ps`).  
- **Página não carrega** → Confira se o container está ativo (`docker-compose ps`).  

---

## 🔮 Próximos Passos
Na próxima atividade vamos explorar os conceitos de **Proxy (Forward e Reverse)**, entendendo como ele se posiciona entre cliente e servidor para adicionar segurança.
