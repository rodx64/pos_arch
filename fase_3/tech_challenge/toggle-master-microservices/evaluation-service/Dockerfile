# ==========================
# 🏗️ STAGE 1 — Builder
# ==========================
# Este estágio monta um ambiente temporário para COMPILAR a aplicação Go.
# Inclui o Go completo para build
FROM golang:1.21-alpine AS builder

# Diretório de trabalho
WORKDIR /app

# Instala ferramentas necessárias (ex: git para baixar dependências)
RUN apk add --no-cache git

# Copia os arquivos de mod e sum primeiro para aproveitar cache do Docker
COPY go.mod go.sum ./

# Baixa as dependências sem alterar go.mod e go.sum
RUN go mod download

# Copia todo o código da aplicação
COPY . .

# Compila a aplicação em um binário estático
RUN go build -o evaluation-service .

# ==========================
# 🧩 STAGE 2 — Runtime final
# ==========================
# Container final leve, apenas com o binário compilado (Por ser binário não precisa do Go)
FROM alpine:latest

RUN apk add --no-cache curl

# Diretório de trabalho
WORKDIR /app

# Copia o binário do builder
COPY --from=builder /app/evaluation-service .

# Copia arquivos de configuração se necessário (.env etc)
# COPY .env .  # opcional, apenas se quiser usar em dev

# Expõe a porta do serviço
EXPOSE 8004

# Comando padrão para rodar o serviço
CMD ["./evaluation-service"]
