# Requisitos técnicos:

## 1. Cultura DevOps e Arquitetura de Aplicações:

- [x] Execute a aplicação monolítica toggle-master-monolith localmente
para entender seu funcionamento.
- [x] Analise o código e identifique por que ele é considerado um "monolito".
Discuta as [vantagens e desvantagens](#vantagens-e-desvantagens-de-um-monolito-em-um-mvp) dessa abordagem para um
MVP.
- [x] Leia e compreenda os [12-Factor App](#-avaliação-do-projeto-vs-12-factor-app) e identifique quais
deles a aplicação já atende e quais precisariam de ajustes para um
ambiente de produção mais robusto.

## 2. Arquitetura Cloud:
- [x] Desenhe um diagrama de [arquitetura](./arquitetura.md) simples para hospedar a
aplicação na AWS. O diagrama deve incluir:
- [x] Uma VPC com sub-redes públicas e privadas.
- [x] Uma instância EC2 na sub-rede pública para rodar a aplicação.
- [x] Um RDS (PostgreSQL ou MySQL) na sub-rede privada para o banco
  de dados.
- [x] Um Security Group para a EC2 permitindo tráfego HTTP/HTTPS e
 SSH (de um IP específico).
- [x] Um Security Group para o RDS permitindo tráfego apenas do
  Security Group da EC2.


## 📊 Vantagens e Desvantagens de um Monolito em um MVP
### ✅  Vantagens:
- Simplicidade para o desenvolvimento inicial e testes
- Rapidez no desenvolvimento e iteração de novas features, levando à um menor `Time to Market`
- Menor complexidade na infraestrutura
- Custos iniciais menores (times pequenos, recursos de infra reduzidos, etc)

### ❌ Desvantagens:
- Dificuldade em escalar
- Dificuldade no desenvolvimento simultâneo
- Deploy falho pode derrubar todo o sistema

## 📊 Avaliação do Projeto vs 12-Factor App


### ✅ Atende
* 🔎 **Codebase** (Uma única base de código por aplicação, versionada.)
  - É um monolito com build único.


* 🔎 **Dependências** (devem ser explícitas e isoladas.)
  - Utiliza requirements.txt para controle de dependências.


* 🔎 **Config** (Configurações (credenciais, URLs, portas) devem ser externas ao código.)
  - Projeto já utilizava variáveis de ambiente e aproveitei para externalizar em outros serviços, tentando deixar a aplicação o mais agnóstica possível.


* 🔎 **Backing Services** (Serviços externos (Bancos, filas, caches, etc) devem ser plugáveis, tratados como recursos.)
  - Os recursos externos (RDS, Parameter Store, Secrets Manager) podem ser substituídos


* 🔎 **Port binding** (A aplicação deve se expor diretamente via porta, sem depender de servidor externo (ex: Apache))
  - Atende pois faz o bind via Docker

### ⚠️ Parcialmente 
* 🔎 **Disposability** (Os processos devem ser rápidos para iniciar e parar, maximizando robustez, resiliência e escalabilidade.)
  - Ao usar Docker, o container pode ser considerado rápido para chavear entre os processos, entretanto: 
    - Não há tratamento de shutdown graceful (Por exemplo, fechar as conexões com RDS antes de finalizar).
    - Chamada do init_db acopla o start da aplicação ao estado do banco. (Deveria ser executado apenas quando necessário)

### ❌ Não Atende
* 🔎 **Build, Release, Run** (O ciclo deve ser separado: Build (compila imagem), Release (combina build + config), Run (executa))
  - Não atende pois todos steps estão juntos. Para atender precisaria de uma pipeline CI/CD


* 🔎 **Concurrency** (Escala horizontal com múltiplos processos/instâncias.)
  - Precisaria rodar em mais instâncias EC2/ECS para realmente escalar. Atualmente pode escalar apenas verticalmente (via hardware)


* 🔎 **Dev/prod parity** (O ambiente de dev deve ser o mais próximo possível do de produção)
  - Ainda há gaps a serem corrigidos entre dev e prod.


* 🔎 **Logs** (Logs devem ser tratados como fluxo de eventos contínuo, enviados a stdout/stderr.)
  - Hoje temos apenas alguns prints não estruturados no console, sem praticamente nenhuma relação com um serviço centralizador como o Datadog, Cloudwatch, etc.


* 🔎 **Admin processes** (Tarefas administrativas (ex: migrações DB) devem ser processos fora do ciclo principal)
  - Considerando um dos pontos, o uso do flask init-db sempre no entrypoint. 