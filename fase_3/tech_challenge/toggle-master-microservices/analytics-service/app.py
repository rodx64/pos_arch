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

# Configura o logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
log = logging.getLogger(__name__)

# Carrega .env para desenvolvimento local
load_dotenv()

# --- Configuração ---
AWS_REGION = os.getenv("AWS_REGION")
SQS_QUEUE_URL = os.getenv("AWS_SQS_URL")
DYNAMODB_TABLE_NAME = os.getenv("AWS_DYNAMODB_TABLE")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")   # local | dev

if not all([AWS_REGION, SQS_QUEUE_URL, DYNAMODB_TABLE_NAME]):
    log.critical("Erro: AWS_REGION, AWS_SQS_URL, e AWS_DYNAMODB_TABLE devem ser definidos.")
    sys.exit(1)

# --- Clientes Boto3 ---
# Criamos a sessão uma vez
try:
    session = boto3.Session(region_name=AWS_REGION)

    if ENVIRONMENT == "local" and AWS_ENDPOINT_URL:
        log.info("🧱 Ambiente local detectado — conectando ao LocalStack.")
        sqs_client = session.client("sqs", endpoint_url=AWS_ENDPOINT_URL)
        dynamodb_client = session.client("dynamodb", endpoint_url=AWS_ENDPOINT_URL)
    else:
        log.info("☁️ Ambiente remoto detectado — conectando à AWS real.")
        sqs_client = session.client("sqs")
        dynamodb_client = session.client("dynamodb")
    log.info(f"Clientes Boto3 inicializados na região {AWS_REGION}")
except NoCredentialsError:
    log.critical("Credenciais da AWS não encontradas. Verifique seu ambiente.")
    sys.exit(1)
except Exception as e:
    log.critical(f"Erro ao inicializar o Boto3: {e}")
    sys.exit(1)

# Variáveis de controle do worker
sqs_ok = False
dynamo_ok = False
worker_started = False
last_heartbeat = 0
WAIT_TIME_SECONDS = 20
HEALTH_MONITOR_INTERVAL = 10
HEARTBEAT_INTERVAL = WAIT_TIME_SECONDS + 5

# --- Heartbeat do Worker ---
def worker_heartbeat():
    global last_heartbeat
    last_heartbeat = time.time()

# --- SQS Worker ---

def process_message(message):
    """ Processa uma única mensagem SQS e a insere no DynamoDB """
    try:
        log.info(f"Processando mensagem ID: {message['MessageId']}")
        body = json.loads(message['Body'])
        
        # Gera um ID único para o item no DynamoDB
        event_id = str(uuid.uuid4())
        
        # Constrói o item no formato do DynamoDB
        item = {
            'event_id': {'S': event_id},
            'user_id': {'S': body['user_id']},
            'flag_name': {'S': body['flag_name']},
            'result': {'BOOL': body['result']},
            'timestamp': {'S': body['timestamp']}
        }
        
        # Insere no DynamoDB
        dynamodb_client.put_item(
            TableName=DYNAMODB_TABLE_NAME,
            Item=item
        )
        
        log.info(f"Evento {event_id} (Flag: {body['flag_name']}) salvo no DynamoDB.")
        
        # Se tudo deu certo, deleta a mensagem da fila
        sqs_client.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=message['ReceiptHandle']
        )
        
    except json.JSONDecodeError:
        log.error(f"Erro ao decodificar JSON da mensagem ID: {message['MessageId']}")
        # Não deleta a mensagem, pode ser uma "poison pill"
    except ClientError as e:
        log.error(f"Erro do Boto3 (DynamoDB ou SQS) ao processar {message['MessageId']}: {e}")
        # Não deleta a mensagem, tenta novamente
    except Exception as e:
        log.error(f"Erro inesperado ao processar {message['MessageId']}: {e}")
        # Não deleta a mensagem, tenta novamente

def sqs_worker_loop():
    """ Loop principal do worker que ouve a fila SQS """
    log.info("Iniciando o worker SQS...")
    while True:
        try:
            if not (sqs_ok and dynamo_ok):
                log.debug("Dependência indisponível (SQS/Dynamo). Worker em espera.")
                worker_heartbeat()
                time.sleep(2)
                continue

            # Long-polling: espera até 20s por mensagens
            response = sqs_client.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=10,  # Processa em lotes de até 10
                WaitTimeSeconds=WAIT_TIME_SECONDS
            )
            messages = response.get('Messages', [])

            if messages:
                log.info(f"Recebidas {len(messages)} mensagens.")
                for message in messages:
                    process_message(message)
            else:
                log.debug("Nenhuma mensagem recebida no poll.")

            worker_heartbeat()
                
        except ClientError as e:
            log.error(f"Erro do Boto3 no loop principal do SQS: {e}")
            worker_heartbeat()
            time.sleep(10) # Pausa antes de tentar novamente
        except Exception as e:
            log.error(f"Erro inesperado no loop principal do SQS: {e}")
            worker_heartbeat()
            time.sleep(10)

def validate_sqs():
    global sqs_ok
    try:
        sqs_client.get_queue_attributes(
            QueueUrl=SQS_QUEUE_URL,
            AttributeNames=["ApproximateNumberOfMessages"]
        )
        if not sqs_ok:
            log.info("SQS acessível")
        sqs_ok = True
    except Exception as e:
        if sqs_ok:
            log.error(f"SQS inacessível: {e}")
        sqs_ok = False

def validate_dynamo():
    global dynamo_ok
    try:
        dynamodb_client.describe_table(TableName=DYNAMODB_TABLE_NAME)
        if not dynamo_ok:
            log.info("DynamoDB acessível")
        dynamo_ok = True
    except Exception as e:
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
                if new_started:
                    log.info("Worker marcado como STARTED (dependências OK).")
                else:
                    log.warning("Worker marcado como NOT STARTED (dependências NOK).")
            worker_started = new_started
        except Exception as e:
            log.error(f"Erro no health monitor: {e}")
        time.sleep(HEALTH_MONITOR_INTERVAL)

app = Flask(__name__)

# --- Probes ---
@app.route('/health/startup')
def health_startup():
    if not worker_started:
        return jsonify({"status": "not-started"}), 500
    return jsonify({"status": "started"}), 200

@app.route('/health/live')
def health_live():
    global last_heartbeat

    if time.time() - last_heartbeat > HEARTBEAT_INTERVAL:
        return jsonify({"status": "dead"}), 500

    return jsonify({"status": "alive"}), 200


@app.route('/health/ready')
def health_ready():
    global last_heartbeat

    if not worker_started:
        return jsonify({"status": "not-ready"}), 500

    if time.time() - last_heartbeat > HEARTBEAT_INTERVAL:
        return jsonify({"status": "not-ready"}), 500

    return jsonify({"status": "ready"}), 200

# --- Inicialização ---
def start_worker():
    """ Inicia o worker SQS em uma thread separada """
    t = threading.Thread(target=sqs_worker_loop, daemon=True)
    t.start()

def start_health_monitor():
    t = threading.Thread(target=health_monitor, daemon=True)
    t.start()

validate_sqs()
validate_dynamo()
worker_started = sqs_ok and dynamo_ok

start_health_monitor()
start_worker()

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8005))
    app.run(host='0.0.0.0', port=port, debug=False)
