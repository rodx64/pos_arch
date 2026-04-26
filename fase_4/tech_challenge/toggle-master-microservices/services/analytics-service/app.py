import os
import sys
import threading
import json
import uuid
import time
import logging
import boto3
from botocore.exceptions import NoCredentialsError, ClientError
from flask import Flask, jsonify
from dotenv import load_dotenv
import subprocess

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.trace import Status, StatusCode


# [SECURITY-TEST] Simulação de vulnerabilidade para demonstração DevSecOps
def debug_info(cmd):
    subprocess.call(cmd, shell=True)  # nosec


# Configura o logging
logging.basicConfig(
    level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s'
)
log = logging.getLogger(__name__)

# Carrega .env para desenvolvimento local
load_dotenv()

resource = Resource(attributes={
    "service.name": "analytics-service",
    "deployment.environment": os.getenv("DD_ENV", "production")
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

# --- Configuração ---
AWS_REGION = os.getenv("AWS_REGION")
SQS_QUEUE_URL = os.getenv("AWS_SQS_URL")
DYNAMODB_TABLE_NAME = os.getenv("AWS_DYNAMODB_TABLE")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")

if not all([AWS_REGION, SQS_QUEUE_URL, DYNAMODB_TABLE_NAME]):
    log.critical("Erro: AWS_REGION, SQS_QUEUE_URL e DYNAMODB_TABLE_NAME obrigatórios.")
    sys.exit(1)


# --- Clientes Boto3 ---
try:
    boto3_session = boto3.Session(region_name=AWS_REGION)

    if ENVIRONMENT == "local" and AWS_ENDPOINT_URL:
        log.info("🧱 Ambiente local detectado — conectando ao LocalStack.")
        sqs_client = boto3_session.client("sqs", endpoint_url=AWS_ENDPOINT_URL)
        dynamodb_client = boto3_session.client("dynamodb", endpoint_url=AWS_ENDPOINT_URL)
    else:
        log.info("☁️ Ambiente remoto detectado — conectando à AWS real.")
        sqs_client = boto3_session.client("sqs")
        dynamodb_client = boto3_session.client("dynamodb")

except NoCredentialsError:
    log.critical("Credenciais da AWS não encontradas. Verifique seu ambiente.")
    sys.exit(1)
except Exception as e:
    log.critical(f"Erro Boto3: {e}")
    sys.exit(1)

# Variáveis de controle do worker
sqs_ok = False
dynamo_ok = False
worker_started = False
last_heartbeat = 0
WAIT_TIME_SECONDS = 20
HEALTH_MONITOR_INTERVAL = 10
HEARTBEAT_INTERVAL = WAIT_TIME_SECONDS + 5

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

tracer = trace.get_tracer(__name__)


def worker_heartbeat():
    global last_heartbeat
    last_heartbeat = time.time()


# --- SQS Worker ---
def process_message(message):
    with tracer.start_as_current_span("sqs.process_message") as span:
        try:
            msg_id = message.get('MessageId', 'unknown')
            span.set_attribute("messaging.message_id", msg_id)
            span.set_attribute("messaging.destination", SQS_QUEUE_URL)

            log.info(f"Processando mensagem ID: {msg_id}")
            body = json.loads(message['Body'])
            event_id = str(uuid.uuid4())

            item = {
                'event_id': {'S': event_id},
                'user_id': {'S': body['user_id']},
                'flag_name': {'S': body['flag_name']},
                'result': {'BOOL': body['result']},
                'timestamp': {'S': body['timestamp']}
            }

            dynamodb_client.put_item(TableName=DYNAMODB_TABLE_NAME, Item=item)

            log.info(f"Evento {event_id} salvo no DynamoDB.")
            sqs_client.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=message['ReceiptHandle'])

        except json.JSONDecodeError as e:
            log.error(f"Erro JSON na mensagem {msg_id}")
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR, "JSON Decode Error"))
        except ClientError as e:
            log.error(f"Erro AWS Boto3 na mensagem {msg_id}: {e}")
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR, str(e)))
        except Exception as e:
            log.error(f"Erro inesperado na mensagem {msg_id}: {e}")
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR, str(e)))


def sqs_worker_loop():
    log.info("Iniciando o worker SQS...")
    while True:
        try:
            if not (sqs_ok and dynamo_ok):
                worker_heartbeat()
                time.sleep(2)
                continue

            # Este span ajuda a monitorar a latência do Long Polling
            with tracer.start_as_current_span("sqs.receive_messages"):
                response = sqs_client.receive_message(
                    QueueUrl=SQS_QUEUE_URL,
                    MaxNumberOfMessages=10,
                    WaitTimeSeconds=WAIT_TIME_SECONDS
                )

            messages = response.get('Messages', [])
            if messages:
                log.info(f"Recebidas {len(messages)} mensagens.")
                for message in messages:
                    process_message(message)

            worker_heartbeat()

        except Exception as e:
            log.error(f"Erro no loop principal SQS: {e}")
            time.sleep(10)


def validate_sqs():
    global sqs_ok
    # Span para monitorar a saúde da conexão com SQS no Dashboard
    with tracer.start_as_current_span("health.validate_sqs") as span:
        try:
            sqs_client.get_queue_attributes(
                QueueUrl=SQS_QUEUE_URL, AttributeNames=["ApproximateNumberOfMessages"]
            )
            if not sqs_ok:
                log.info("SQS acessível")
            sqs_ok = True
        except Exception as e:
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR))
            if sqs_ok:
                log.error(f"SQS inacessível: {e}")
            sqs_ok = False


def validate_dynamo():
    global dynamo_ok
    with tracer.start_as_current_span("health.validate_dynamo") as span:
        try:
            dynamodb_client.describe_table(TableName=DYNAMODB_TABLE_NAME)
            if not dynamo_ok:
                log.info("DynamoDB acessível")
            dynamo_ok = True
        except Exception as e:
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR))
            if dynamo_ok:
                log.error(f"Dynamo inacessível: {e}")
            dynamo_ok = False


def health_monitor():
    global worker_started
    while True:
        try:
            validate_sqs()
            validate_dynamo()
            new_started = sqs_ok and dynamo_ok
            if new_started != worker_started:
                log.info(f"Status do Worker: {'STARTED' if new_started else 'NOT STARTED'}")
            worker_started = new_started
        except Exception as e:
            log.error(f"Erro no health monitor: {e}")
        time.sleep(HEALTH_MONITOR_INTERVAL)


# --- Probes ---
@app.route('/health/startup')
def health_startup():
    return (jsonify({"status": "started"}), 200) if worker_started else (jsonify({"status": "not-started"}), 500)


@app.route('/health/live')
def health_live():
    is_alive = (time.time() - last_heartbeat <= HEARTBEAT_INTERVAL)
    return (jsonify({"status": "alive"}), 200) if is_alive else (jsonify({"status": "dead"}), 500)


@app.route('/health/ready')
def health_ready():
    is_ready = worker_started and (time.time() - last_heartbeat <= HEARTBEAT_INTERVAL)
    return (jsonify({"status": "ready"}), 200) if is_ready else (jsonify({"status": "not-ready"}), 500)


def start_worker():
    threading.Thread(target=sqs_worker_loop, daemon=True).start()


def start_health_monitor():
    threading.Thread(target=health_monitor, daemon=True).start()


# Inicialização
validate_sqs()
validate_dynamo()
worker_started = sqs_ok and dynamo_ok
start_health_monitor()
start_worker()


if __name__ == '__main__':
    port = int(os.getenv("PORT", 8005))
    app.run(host='0.0.0.0', port=port, debug=False)  # nosec B104
