FROM python:3.11-slim

WORKDIR /app

# Atualiza pacotes básicos e instala Flask
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir flask

COPY api.py /app/api.py

EXPOSE 5000

CMD ["python", "api.py"]
