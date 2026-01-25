#!/bin/bash
# Script de verificação de saúde do Nginx
# Precisa estar acessível para o Keepalived e ser executável.

# Verifica se o Nginx responde em localhost
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1)

if [ "$HTTP_CODE" -eq "200" ]; then
    echo "Nginx está OK (HTTP 200)"
    exit 0 # Sucesso
else
    echo "Nginx está DOWN (HTTP Code: $HTTP_CODE)"
    exit 1 # Falha
fi