#!/usr/bin/env bash

# Bastion
export BASTION_USER=ec2-user
export BASTION_KEY=toggle-key.pem
export BASTION_HOST=xxx

# AUTH RDS
export POSTGRES_PORT=5432
export POSTGRES_LOCAL_AUTH_PORT=5433
export POSTGRES_LOCAL_FLAG_PORT=5434
export POSTGRES_LOCAL_TARG_PORT=5435
export POSTGRES_AUTH_HOST=xxx
export POSTGRES_FLAG_HOST=xxx
export POSTGRES_TARG_HOST=xxx

# Redis
export REDIS_HOST=xxx
export REDIS_PORT=6379
export REDIS_LOCAL_PORT=6379

# EKS API (endpoint privado)
export EKS_ENDPOINT=xxx
export EKS_PORT=443
export EKS_LOCAL_PORT=8443
