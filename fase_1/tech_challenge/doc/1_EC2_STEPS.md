# Durante a execução do projeto

### Fluxo de Comandos

```
// Logando no EC2
ssh -i fase_1/tech_challenge/files/toggle-key.pem ubuntu@xx.xxx.xxx.xx

// Criando as pastas
mkdir -p /home/ubuntu/toggle-master
cd toggle-master

// Buildando o app
docker build -t toggle-app .

// Executando o projeto com bind nas portas
docker run -p 5000:5000 toggle-master-app 

// Copiando os arquivos para o EC2
scp -i tech_challenge/files/toggle-key.pem \
    ./tech_challenge/toggle-master-monolith/app.py \
    ./tech_challenge/toggle-master-monolith/requirements.txt \
    ./tech_challenge/toggle-master-monolith/Dockerfile \
    ./tech_challenge/toggle-master-monolith/entrypoint.sh \
    ubuntu@xx.xxx.xxx.xx:/home/ubuntu/toggle-master/
```

### Debug EC2

```
// Escutar portas (tulnp - Tpc/Udp/Listening/Number(ip:porta)/PID)
sudo netstat -tulnp 

// Analisar tráfego chegando na porta:
sudo tcpdump -i any tcp port 5000

// Analisar processos executando na porta:
sudo lsof -i :5000

// Logando no DB para validar os dados criados
psql 'host=togglemaster.xxx.us-east-1.rds.amazonaws.com port=5432 dbname=postgres user=xxx password=xxx

select * from flags;
```