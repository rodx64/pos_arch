FROM nginx:alpine

# Instalar dependências básicas
RUN apk add --no-cache \
    curl \
    wget \
    unzip

# Criar diretórios necessários
RUN mkdir -p /etc/modsecurity.d \
    && mkdir -p /var/log/modsec_audit \
    && mkdir -p /var/www/html

# Baixar e configurar OWASP Core Rule Set (simulado)
RUN mkdir -p /etc/modsecurity.d/owasp-crs

# Copiar arquivos de configuração
COPY nginx.conf /etc/nginx/nginx.conf
COPY modsecurity.conf /etc/modsecurity.d/modsecurity.conf
COPY custom-rules.conf /etc/modsecurity.d/custom-rules.conf
COPY index.html /var/www/html/


EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]