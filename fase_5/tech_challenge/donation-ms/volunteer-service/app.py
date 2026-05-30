import os
import sys
import uuid
import time
import logging
import boto3
import botocore.exceptions
from flask import Flask, request, jsonify
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
log = logging.getLogger(__name__)

load_dotenv()

app = Flask(__name__)

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")
DYNAMODB_TABLE = os.getenv("AWS_DYNAMODB_TABLE")

if not DYNAMODB_TABLE:
    log.critical("Erro: AWS_DYNAMODB_TABLE não definida.")
    sys.exit(1)


def wait_for_service(client, retries=10, delay=2):
    for attempt in range(1, retries + 1):
        try:
            client.list_tables(Limit=1)
            return
        except Exception:
            log.info(f"Aguardando serviço AWS estar disponível ({attempt}/{retries})...")
            time.sleep(delay)
    raise RuntimeError("Serviço AWS não ficou disponível a tempo")


def ensure_dynamodb_table(dynamodb, table_name):
    table = dynamodb.Table(table_name)
    try:
        table.load()
        log.info(f"Tabela DynamoDB existente encontrada: {table_name}")
        return table
    except botocore.exceptions.ClientError as error:
        code = error.response.get("Error", {}).get("Code")
        if code == "ResourceNotFoundException":
            log.info(f"Tabela {table_name} não encontrada. Criando...")
            table = dynamodb.create_table(
                TableName=table_name,
                AttributeDefinitions=[{"AttributeName": "volunteer_id", "AttributeType": "S"}],
                KeySchema=[{"AttributeName": "volunteer_id", "KeyType": "HASH"}],
                BillingMode="PAY_PER_REQUEST",
            )
            table.wait_until_exists()
            log.info(f"Tabela DynamoDB criada: {table_name}")
            return table
        raise


try:
    if AWS_ENDPOINT_URL:
        log.info("🧱 Ambiente local detectado — conectando ao LocalStack.")
        dynamodb = boto3.resource(
            "dynamodb",
            region_name=AWS_REGION,
            endpoint_url=AWS_ENDPOINT_URL,
        )
    else:
        dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)

    wait_for_service(dynamodb.meta.client)
    table = ensure_dynamodb_table(dynamodb, DYNAMODB_TABLE)
    log.info(f"Conectado à tabela DynamoDB: {DYNAMODB_TABLE}")
except Exception as e:
    log.critical(f"Falha ao conectar no DynamoDB: {e}")
    sys.exit(1)

@app.route('/health')
def health():
    return jsonify({"status": "ok", "service": "volunteer-service"})

@app.route('/volunteers', methods=['POST'])
def register_volunteer():
    data = request.get_json()
    if not data or not all(k in data for k in ('name', 'email', 'ngo_id')):
        return jsonify({"error": "Campos obrigatórios ausentes"}), 400
    
    volunteer_id = str(uuid.uuid4())
    item = {
        'volunteer_id': volunteer_id,
        'name': data['name'],
        'email': data['email'],
        'ngo_id': int(data['ngo_id']),
        'registered_at': str(int(time.time()))
    }
    
    try:
        table.put_item(Item=item)
        return jsonify(item), 201
    except Exception as e:
        log.error(f"Erro ao salvar voluntário no DynamoDB: {e}")
        return jsonify({"error": "Erro interno ao processar dados"}), 500

@app.route('/volunteers/<int:ngo_id>', methods=['GET'])
def get_volunteers_by_ngo(ngo_id):
    try:
        response = table.scan(
            FilterExpression=boto3.dynamodb.conditions.Attr('ngo_id').eq(ngo_id)
        )
        return jsonify(response.get('Items', [])), 200
    except Exception as e:
        log.error(f"Erro ao buscar dados no DynamoDB: {e}")
        return jsonify({"error": "Erro interno"}), 500

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8083))
    app.run(host='0.0.0.0', port=port)
