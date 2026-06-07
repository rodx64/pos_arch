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
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

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
    setuptools==81.0.0 wheel \
    opentelemetry-distro \
    opentelemetry-exporter-otlp || true

RUN opentelemetry-bootstrap -a install

COPY --from=builder /install /usr/local
COPY . .

RUN adduser -D appuser

ENV PROMETHEUS_MULTIPROC_DIR=/tmp/prometheus_multiproc
RUN mkdir -p /tmp/prometheus_multiproc && \
    chown appuser:appuser /tmp/prometheus_multiproc && \
    chmod 755 /tmp/prometheus_multiproc

USER appuser

EXPOSE 8081


CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:8081", "app:app"]
