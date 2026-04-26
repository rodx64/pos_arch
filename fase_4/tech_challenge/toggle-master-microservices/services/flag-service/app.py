import os
import sys
import logging
import psycopg2
import requests
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool
from flask import Flask, request, jsonify
from dotenv import load_dotenv
from functools import wraps

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor

# --- Prometheus Metrics ---
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Gauge, Histogram

# Configuração de Identidade do Serviço para o OTel
resource = Resource(attributes={
    "service.name": "flag-service",
    "deployment.environment": os.getenv("DD_ENV", "production")
})

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector.monitoring.svc.cluster.local:4317"),
    insecure=True
))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

RequestsInstrumentor().instrument()
Psycopg2Instrumentor().instrument()

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)
load_dotenv()

metrics = PrometheusMetrics(app)

flags_created_total = Counter('flags_created_total', 'Total de feature flags criadas')
flags_updated_total = Counter('flags_updated_total', 'Total de feature flags atualizadas')
flags_deleted_total = Counter('flags_deleted_total', 'Total de feature flags deletadas')
flags_active_total = Gauge('flags_active_total', 'Total de feature flags com is_enabled=true')
auth_validation_total = Counter('auth_validation_total', 'Validações de auth por resultado', ['result'])
db_up = Gauge('db_up', 'Status da conexão com PostgreSQL')
auth_service_up = Gauge('auth_service_up', 'Status do serviço de Autenticação')
db_query_duration_seconds = Histogram('db_query_duration_seconds', 'Duração das queries SQL', ['operation'])

# --- Configurações de Ambiente ---
DATABASE_URL = os.getenv("DATABASE_URL")
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL")

if not DATABASE_URL or not AUTH_SERVICE_URL:
    log.critical("Erro: DATABASE_URL e AUTH_SERVICE_URL devem ser definidos.")
    sys.exit(1)

try:
    pool = SimpleConnectionPool(1, 5, dsn=DATABASE_URL)
    log.info("Pool de conexões com o PostgreSQL inicializado.")
    db_up.set(1)
except psycopg2.OperationalError as e:
    log.critical("Erro fatal ao conectar ao PostgreSQL: %s", e)
    db_up.set(0)
    sys.exit(1)


def refresh_active_flags_gauge():
    """Sincroniza o gauge de métricas com o estado atual do banco."""
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM flags WHERE is_enabled = true")
        count = cur.fetchone()[0]
        flags_active_total.set(count)
    except Exception as e:
        log.error("Erro ao atualizar gauge de flags ativas: %s", e)
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


# --- Middleware de Autenticação ---
def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            auth_validation_total.labels(result="failure").inc()
            return jsonify({"error": "Authorization header obrigatório"}), 401

        try:
            validate_url = f"{AUTH_SERVICE_URL}/validate"
            response = requests.get(validate_url, headers={"Authorization": auth_header}, timeout=3)

            if response.status_code != 200:
                log.warning("Falha na validação da chave. Status: %d", response.status_code)
                auth_validation_total.labels(result="failure").inc()
                return jsonify({"error": "Chave de API inválida"}), 401

            auth_validation_total.labels(result="success").inc()
            auth_service_up.set(1)

        except requests.exceptions.Timeout:
            log.error("Timeout ao conectar com o auth-service")
            auth_validation_total.labels(result="timeout").inc()
            auth_service_up.set(0)
            return jsonify({"error": "Serviço de autenticação offline"}), 504
        except Exception as e:
            log.error("Erro inesperado na validação de auth: %s", e)
            auth_validation_total.labels(result="error").inc()
            auth_service_up.set(0)
            return jsonify({"error": "Erro interno no serviço de auth"}), 503

        return f(*args, **kwargs)
    return decorated


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/flags", methods=["POST"])
@require_auth
def create_flag():
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "'name' é obrigatório"}), 400

    name = data["name"]
    description = data.get("description", "")
    is_enabled = data.get("is_enabled", False)

    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="create").time():
            cur.execute(
                "INSERT INTO flags (name, description, is_enabled, created_at, updated_at) "
                "VALUES (%s, %s, %s, NOW(), NOW()) RETURNING *",
                (name, description, is_enabled),
            )
            new_flag = cur.fetchone()
        conn.commit()
        flags_created_total.inc()
        refresh_active_flags_gauge()
        log.info("Flag '%s' criada com sucesso.", name)
        return jsonify(new_flag), 201
    except psycopg2.IntegrityError:
        if conn:
            conn.rollback()
        return jsonify({"error": f"Flag '{name}' já existe"}), 409
    except Exception as e:
        if conn:
            conn.rollback()
        log.error("Erro ao criar flag: %s", e)
        return jsonify({"error": "Erro interno do servidor"}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/flags", methods=["GET"])
@require_auth
def get_flags():
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="read").time():
            cur.execute("SELECT * FROM flags ORDER BY name")
            flags = cur.fetchall()
        return jsonify(flags)
    except Exception as e:
        log.error("Erro ao buscar flags: %s", e)
        return jsonify({"error": "Erro interno do servidor"}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/flags/<string:name>", methods=["GET"])
@require_auth
def get_flag(name):
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="read").time():
            cur.execute("SELECT * FROM flags WHERE name = %s", (name,))
            flag = cur.fetchone()
        if not flag:
            return jsonify({"error": "Flag não encontrada"}), 404
        return jsonify(flag)
    except Exception as e:
        log.error("Erro ao buscar flag '%s': %s", name, e)
        return jsonify({"error": "Erro interno do servidor"}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/flags/<string:name>", methods=["PUT"])
@require_auth
def update_flag(name):
    data = request.get_json()
    if not data:
        return jsonify({"error": "Dados obrigatórios"}), 400

    fields = []
    values = []
    if "description" in data:
        fields.append("description = %s")
        values.append(data["description"])
    if "is_enabled" in data:
        fields.append("is_enabled = %s")
        values.append(data["is_enabled"])

    if not fields:
        return jsonify({"error": "Nenhum campo para atualizar"}), 400

    values.append(name)
    query = f"UPDATE flags SET {', '.join(fields)}, updated_at = NOW() WHERE name = %s RETURNING *"

    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="update").time():
            cur.execute(query, tuple(values))
            if cur.rowcount == 0:
                return jsonify({"error": "Flag não encontrada"}), 404
            updated_flag = cur.fetchone()
        conn.commit()
        flags_updated_total.inc()
        refresh_active_flags_gauge()
        log.info("Flag '%s' atualizada.", name)
        return jsonify(updated_flag), 200
    except Exception as e:
        if conn:
            conn.rollback()
        log.error("Erro ao atualizar flag: %s", e)
        return jsonify({"error": "Erro interno do servidor"}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/flags/<string:name>", methods=["DELETE"])
@require_auth
def delete_flag(name):
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor()
        with db_query_duration_seconds.labels(operation="delete").time():
            cur.execute("DELETE FROM flags WHERE name = %s", (name,))
            if cur.rowcount == 0:
                return jsonify({"error": "Flag não encontrada"}), 404
        conn.commit()
        flags_deleted_total.inc()
        refresh_active_flags_gauge()
        log.info("Flag '%s' deletada.", name)
        return "", 204
    except Exception:
        if conn:
            conn.rollback()
        return jsonify({"error": "Erro interno do servidor"}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8002))
    # #nosec B104 - Aceitável para ambiente de container com Gunicorn/K8s
    app.run(host="0.0.0.0", port=port, debug=False)
