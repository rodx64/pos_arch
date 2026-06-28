#!/usr/bin/env bash

# AUTH RDS
export POSTGRES_PORT=5432
export POSTGRES_LOCAL_AUTH_PORT=5433
export POSTGRES_LOCAL_FLAG_PORT=5434
export POSTGRES_LOCAL_TARG_PORT=5435
export POSTGRES_AUTH_HOST=auth-db.cyqhxxmitsv1.us-east-1.rds.amazonaws.com
export POSTGRES_FLAG_HOST=flag-db.cyqhxxmitsv1.us-east-1.rds.amazonaws.com
export POSTGRES_TARG_HOST=targeting-db.cyqhxxmitsv1.us-east-1.rds.amazonaws.com
