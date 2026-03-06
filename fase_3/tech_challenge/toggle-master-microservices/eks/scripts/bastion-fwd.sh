#!/usr/bin/env bash
set -e

source ./env.sh

echo "🚀 Abrindo túneis via Bastion..."

ssh -i "$BASTION_KEY" \
  -o ExitOnForwardFailure=yes \
  -N \
  -L ${POSTGRES_LOCAL_AUTH_PORT}:${POSTGRES_AUTH_HOST}:${POSTGRES_PORT} \
  -L ${POSTGRES_LOCAL_FLAG_PORT}:${POSTGRES_FLAG_HOST}:${POSTGRES_PORT} \
  -L ${POSTGRES_LOCAL_TARG_PORT}:${POSTGRES_TARG_HOST}:${POSTGRES_PORT} \
  ${BASTION_USER}@${BASTION_HOST}
