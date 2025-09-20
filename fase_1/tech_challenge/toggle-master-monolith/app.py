import os
from functools import lru_cache

from flask import Flask, request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
import boto3
from botocore.exceptions import ClientError
import json

app = Flask(__name__)
_db_inicializado = False

USE_LOCALSTACK = os.getenv("LOCALSTACK", "false").lower() == "true"
AWS_REGION = os.getenv("AWS_REGION")
boto3_args = {"region_name": AWS_REGION}

if USE_LOCALSTACK:
    boto3_args["endpoint_url"] = os.getenv("AWS_ENDPOINT_URL", "http://localhost:4566")
    boto3_args["aws_access_key_id"] = "test"
    boto3_args["aws_secret_access_key"] = "test"
    print("⚡ Conectado ao Localstack...")
else:
    print(f"⚡ Conectado à AWS na região {AWS_REGION}...")

@lru_cache(maxsize=1)
def _get_parameters():
    """
    Busca os parâmetros do SSM Parameter Store, incluindo o nome do Secret do Secrets Manager.
    """
    print("🔍 Buscando parâmetros no SSM...")
    client = boto3.client("ssm", **boto3_args)
    try:
        params = {
            "host": client.get_parameter(Name="/togglemaster/DB_HOST")["Parameter"]["Value"],
            "dbname": client.get_parameter(Name="/togglemaster/DB_NAME")["Parameter"]["Value"],
            "port": client.get_parameter(Name="/togglemaster/DB_PORT")["Parameter"]["Value"],
            "secret_name": client.get_parameter(Name="/togglemaster/SECRET_NAME")["Parameter"]["Value"],
        }
        print(f"✅ Parâmetros obtidos do SSM")
        return params
    except ClientError as e:
        print(f"❌ Falha ao buscar parâmetros no SSM")
        raise e


@lru_cache(maxsize=1)
def _get_secret_dict():
    """
    Busca o Secret no Secrets Manager, usando o nome obtido do Parameter Store.
    """
    params = _get_parameters()
    secret_name = params["secret_name"]
    print(f"🔑 Buscando secret no Secrets Manager...")

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=AWS_REGION
    )
    try:
        secret = json.loads(client.get_secret_value(SecretId=secret_name)['SecretString'])
        print(f"✅ Secret obtido com sucesso")
        return secret
    except ClientError as e:
        print(f"❌ Falha ao buscar secret: {e}")
        raise e


def get_db_connection():
    print("🔗 Tentando conectar ao banco de dados...")
    creds = _get_secret_dict()
    params = _get_parameters()

    try:
        conn = psycopg2.connect(
            user=creds.get("username"),
            password=creds.get("password"),
            host=params["host"],
            dbname=params["dbname"],
            port=params["port"]
        )
        print("✅ Conexão com o banco estabelecida com sucesso!")
        return conn
    except psycopg2.OperationalError as e:
        print(f"❌ Erro de conexão ao banco de dados: {e}")
        raise e


def init_db():
    print("Tentando inicializar a tabela 'flags'...")
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS flags (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) UNIQUE NOT NULL,
                is_enabled BOOLEAN NOT NULL DEFAULT false,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("Tabela 'flags' inicializada com sucesso.")
    except psycopg2.OperationalError as e:
        print(f"Erro de conexão ao inicializar o banco de dados: {e}")
    except Exception as e:
        print(f"Um erro inesperado ocorreu durante a inicialização do DB: {e}")

@app.cli.command("init-db")
def init_db_command():
    init_db()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

@app.route('/flags', methods=['POST'])
def create_flag():
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({"error": "O campo 'name' é obrigatório"}), 400
    
    name = data['name']
    is_enabled = data.get('is_enabled', False)
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO flags (name, is_enabled) VALUES (%s, %s)", (name, is_enabled))
        conn.commit()
    except psycopg2.IntegrityError:
        return jsonify({"error": f"A flag '{name}' já existe"}), 409
    except Exception as e:
        return jsonify({"error": "Erro interno no servidor ao criar a flag", "details": str(e)}), 500
    finally:
        if 'cur' in locals() and not cur.closed:
            cur.close()
        if 'conn' in locals() and not conn.closed:
            conn.close()
            
    return jsonify({"message": f"Flag '{name}' criada com sucesso"}), 201

@app.route('/flags', methods=['GET'])
def get_flags():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT name, is_enabled FROM flags ORDER BY name")
        flags = cur.fetchall()
    except Exception as e:
        return jsonify({"error": "Erro interno no servidor ao buscar as flags", "details": str(e)}), 500
    finally:
        if 'cur' in locals() and not cur.closed:
            cur.close()
        if 'conn' in locals() and not conn.closed:
            conn.close()

    return jsonify(flags), 200

@app.route('/flags/<string:name>', methods=['GET'])
def get_flag_status(name):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT name, is_enabled FROM flags WHERE name = %s", (name,))
        flag = cur.fetchone()
    except Exception as e:
        return jsonify({"error": "Erro interno no servidor ao buscar a flag", "details": str(e)}), 500
    finally:
        if 'cur' in locals() and not cur.closed:
            cur.close()
        if 'conn' in locals() and not conn.closed:
            conn.close()
    
    if flag:
        return jsonify(flag), 200
    return jsonify({"error": "Flag não encontrada"}), 404

@app.route('/flags/<string:name>', methods=['PUT'])
def update_flag(name):
    data = request.get_json()
    if data is None or 'is_enabled' not in data or not isinstance(data['is_enabled'], bool):
        return jsonify({"error": "O campo 'is_enabled' (booleano) é obrigatório"}), 400
        
    is_enabled = data['is_enabled']
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("UPDATE flags SET is_enabled = %s WHERE name = %s", (is_enabled, name))
        
        if cur.rowcount == 0:
            return jsonify({"error": "Flag não encontrada"}), 404
            
        conn.commit()
    except Exception as e:
        return jsonify({"error": "Erro interno no servidor ao atualizar a flag", "details": str(e)}), 500
    finally:
        if 'cur' in locals() and not cur.closed:
            cur.close()
        if 'conn' in locals() and not conn.closed:
            conn.close()
    
    return jsonify({"message": f"Flag '{name}' atualizada"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)