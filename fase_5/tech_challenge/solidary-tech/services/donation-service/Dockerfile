# ==========================
# 🏗️ STAGE 1 — Builder
# ==========================
FROM golang:1.25-alpine AS builder

WORKDIR /src

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags='-s -w' -o /app/donation-service .

# ==========================
# 🧩 STAGE 2 — Runtime final
# ==========================
FROM alpine:3.23 AS runtime

RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=builder /app/donation-service .

RUN adduser -D -u 1000 appuser
USER appuser

EXPOSE 8082

CMD ["./donation-service"]
