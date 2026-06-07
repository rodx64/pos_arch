import os
import uuid
import time
import logging
import boto3
import botocore.exceptions
from boto3.dynamodb.conditions import Attr
from flask import Flask, request, jsonify
from dotenv import load_dotenv
from prometheus_flask_exporter import PrometheusMetrics

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
log = logging.getLogger(__name__)

load_dotenv()

app = Flask(__name__)
metrics = PrometheusMetrics(app)

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")
DYNAMODB_TABLE = os.getenv("AWS_DYNAMODB_TABLE")

dynamodb = None
table = None


def get_dynamodb_resource():
    if AWS_ENDPOINT_URL:
        log.info("🧱 Ambiente local detectado — conectando ao LocalStack.")
        return boto3.resource(
            "dynamodb",
            region_name=AWS_REGION,
            endpoint_url=AWS_ENDPOINT_URL,
        )
    return boto3.resource("dynamodb", region_name=AWS_REGION)


def wait_for_service(client, retries=10, delay=2):
    for attempt in range(1, retries + 1):
        try:
            client.list_tables(Limit=1)
            return
        except Exception:
            log.info(f"Aguardando serviço AWS estar disponível ({attempt}/{retries})...")
            time.sleep(delay)
    raise RuntimeError("Serviço AWS não ficou disponível a tempo")


def init_dynamodb_table(dynamodb_resource=None):
    if not DYNAMODB_TABLE:
        raise RuntimeError("Erro: AWS_DYNAMODB_TABLE não definida.")

    if dynamodb_resource is None:
        dynamodb_resource = get_dynamodb_resource()

    table = dynamodb_resource.Table(DYNAMODB_TABLE)
    try:
        table.load()
        log.info(f"Tabela DynamoDB existente encontrada: {DYNAMODB_TABLE}")
        return table
    except botocore.exceptions.ClientError as error:
        code = error.response.get("Error", {}).get("Code")
        if code == "ResourceNotFoundException":
            log.info(f"Tabela {DYNAMODB_TABLE} não encontrada. Criando...")
            table = dynamodb_resource.create_table(
                TableName=DYNAMODB_TABLE,
                AttributeDefinitions=[{"AttributeName": "volunteer_id", "AttributeType": "S"}],
                KeySchema=[{"AttributeName": "volunteer_id", "KeyType": "HASH"}],
                BillingMode="PAY_PER_REQUEST",
            )
            table.wait_until_exists()
            log.info(f"Tabela DynamoDB criada: {DYNAMODB_TABLE}")
            return table
        raise


def get_table():
    global table
    if table is None:
        dynamodb = get_dynamodb_resource()
        wait_for_service(dynamodb.meta.client)
        table = init_dynamodb_table(dynamodb)
        log.info(f"Conectado à tabela DynamoDB: {DYNAMODB_TABLE}")
    return table


@app.route('/volunteers/health')
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
        get_table().put_item(Item=item)
        return jsonify(item), 201
    except Exception as e:
        log.error(f"Erro ao salvar voluntário no DynamoDB: {e}")
        return jsonify({"error": "Erro interno ao processar dados"}), 500


@app.route('/volunteers/<int:ngo_id>', methods=['GET'])
def get_volunteers_by_ngo(ngo_id):
    try:
        response = get_table().scan(
            FilterExpression=Attr('ngo_id').eq(ngo_id)
        )
        return jsonify(response.get('Items', [])), 200
    except Exception as e:
        log.error(f"Erro ao buscar dados no DynamoDB: {e}")
        return jsonify({"error": "Erro interno"}), 500


if __name__ == '__main__':
    port = int(os.getenv("PORT", 8083))
    host = os.getenv("HOST", "0.0.0.0")  # nosec B104
    app.run(host=host, port=port)
