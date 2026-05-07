# ==========================
# 🏗️ STAGE 1 — Builder
# ==========================
# Este estágio monta um ambiente temporário para COMPILAR e INSTALAR as dependências da aplicação.
# Ele inclui ferramentas pesadas como gcc e build-essential, necessárias apenas para build.
# O resultado é uma pasta /install contendo todos os pacotes Python já prontos (sem cache e sem lixo de build).
# Este estágio NÃO vira um container executável — ele serve apenas de base para o estágio final.
FROM python:3.11-slim AS builder

# Define diretório de trabalho
WORKDIR /app

# Evita geração de arquivos .pyc e ativa logs diretos no terminal
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Instala dependências de compilação temporárias
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copia dependências do projeto
COPY requirements.txt .

# Instala dependências Python no diretório isolado /install
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# ==========================
# 🧹 Docker descarta o container do builder (ele não vai para a imagem final)
# ==========================


# ==========================
# 🧩 STAGE 2 — Runtime final
# ==========================
# Este é o container final e leve, usado em execução (ex: docker compose up flag-service)
# Ele contém apenas o Python, as dependências prontas e o código-fonte da aplicação.
FROM python:3.11-slim AS runtime

# Define diretório de trabalho
WORKDIR /app

# Atualiza pacotes e instala curl (necessário para healthcheck)
RUN apt-get update && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

COPY . .

RUN useradd -m appuser
USER appuser

EXPOSE 8002

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8002", "app:app"]
