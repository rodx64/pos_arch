#!/bin/bash
# Script de verificação avançada do Nginx + serviço crítico

# 1) Health check HTTP no Nginx
# Faz uma requisição local para a página /healthcheck.html
# -s → modo silencioso
# -o /dev/null → descarta saída
# -w "%{http_code}" → captura apenas o código HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/healthcheck.html)

# Se o código de resposta não for 200, considera que o Nginx falhou
if [ "$HTTP_CODE" -ne "200" ]; then
  echo "Nginx não OK"
  exit 1            # Sinaliza falha para o Keepalived
fi

# 2) Health check passivo de um serviço crítico
# Verifica se existe um arquivo de controle (/tmp/FLAG_CRITICO_OK)
# Esse arquivo pode ser criado/atualizado por outro processo/serviço
if [ ! -f /tmp/FLAG_CRITICO_OK ]; then
  echo "Serviço crítico ausente"
  exit 1            # Se o arquivo não existir, considera falha
fi

# Se chegou até aqui → tudo OK
echo "Nginx OK + Serviço crítico OK"
exit 0              # Retorna sucesso (para o Keepalived continuar no ar)
