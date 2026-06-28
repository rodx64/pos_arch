import os
import uuid
import math
import time
import logging
import boto3
import botocore.exceptions
from boto3.dynamodb.conditions import Attr
from flask import Flask, request, jsonify
from dotenv import load_dotenv

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor
from prometheus_flask_exporter import PrometheusMetrics

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
log = logging.getLogger(__name__)

load_dotenv()

resource = Resource(attributes={
    "service.name": "volunteer-service",
    "deployment.environment": os.getenv("DD_ENV", "dev")
})
provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(OTLPSpanExporter(
    endpoint=os.getenv(
        "OTEL_EXPORTER_OTLP_ENDPOINT",
        "http://otel-collector.monitoring.svc.cluster.local:4318/v1/traces"
    ),
))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

RequestsInstrumentor().instrument()
Psycopg2Instrumentor().instrument()

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

metrics = PrometheusMetrics(app)

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")
DYNAMODB_TABLE = os.getenv("AWS_DYNAMODB_TABLE")

# Limites do endpoint sintético de estresse de CPU (/cpu)
CPU_DEFAULT_DURATION_MS = 50
CPU_MAX_DURATION_MS = 500

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


@app.route('/cpu')
def cpu_stress():
    """
    Endpoint sintético de estresse de CPU, usado pelo k6 (k6-load-test.yaml)
    e para calibrar HPA/KEDA. Aceita ?duration_ms=N (padrão 50ms, máximo 500ms).
    Não toca no banco de dados — é puramente computacional (CPU-bound).
    """
    try:
        duration_ms = int(request.args.get('duration_ms', CPU_DEFAULT_DURATION_MS))
    except (TypeError, ValueError):
        duration_ms = CPU_DEFAULT_DURATION_MS

    duration_ms = max(1, min(duration_ms, CPU_MAX_DURATION_MS))

    start = time.perf_counter()
    result = 0.0
    i = 0
    while (time.perf_counter() - start) * 1000 < duration_ms:
        for _ in range(1000):
            i += 1
            result += math.sqrt(i) * math.sin(i)

    return jsonify({
        "status": "ok",
        "service": "volunteer-service",
        "duration_ms": duration_ms,
        "result": result,
    })


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
