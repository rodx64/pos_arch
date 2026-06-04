#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<'EOSQL'
SELECT 'CREATE DATABASE ngo_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ngo_db')\gexec
SELECT 'CREATE DATABASE donation_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'donation_db')\gexec
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname ngo_db <<'EOSQL'
CREATE TABLE IF NOT EXISTS ngos (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    cause VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO ngos (name, email, cause, city) VALUES
('Anjos de Patas', 'contato@anjosdepatas.org', 'Proteção Animal', 'Osasco'),
('Educa Mais', 'info@educamais.org', 'Educação', 'São Paulo');
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname donation_db <<'EOSQL'
CREATE TABLE IF NOT EXISTS donations (
    id SERIAL PRIMARY KEY,
    ngo_id INT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    donor_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
EOSQL
