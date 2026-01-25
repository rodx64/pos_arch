# Base oficial, segura e mínima
FROM debian:stable-slim

# Instala o Apache Bench (apache2-utils) e curl para debug
RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2-utils curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Por padrão chamaremos "ab" via docker-compose exec, então o entrypoint do compose é "sleep infinity"
