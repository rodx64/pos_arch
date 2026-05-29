# ==========================
# 🏗️ STAGE 1 — Builder
# ==========================
FROM python:3.13-alpine AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev \
    linux-headers \
    libffi-dev

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install setuptools wheel -r requirements.txt

# ==========================
# 🧩 STAGE 2 — Runtime final
# ==========================
FROM python:3.13-alpine AS runtime

WORKDIR /app

RUN apk add --no-cache \
    libpq \
    curl \
    libffi

RUN pip install --no-cache-dir \
    opentelemetry-distro \
    opentelemetry-exporter-otlp || true

COPY --from=builder /install /usr/local
COPY . .

RUN adduser -D appuser
USER appuser

EXPOSE 8081

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8081", "app:app"]
