import os
import sys
import psycopg2
import requests
from psycopg2.extras import RealDictCursor, Json
from psycopg2.pool import SimpleConnectionPool
from flask import Flask, request, jsonify
from dotenv import load_dotenv
from functools import wraps
import logging
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Gauge, Histogram

# Configura o logging
logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# Carrega .env para desenvolvimento local
load_dotenv()

app = Flask(__name__)
metrics = PrometheusMetrics(app)  # expõe /metrics automaticamente

# --- Métricas customizadas ---
rules_created_total = Counter(
    'rules_created_total',
    'Total de regras de segmentação criadas'
)
rules_updated_total = Counter(
    'rules_updated_total',
    'Total de regras de segmentação atualizadas'
)
rules_deleted_total = Counter(
    'rules_deleted_total',
    'Total de regras de segmentação deletadas'
)
rules_active_total = Gauge(
    'rules_active_total',
    'Total de regras de segmentação com is_enabled=true'
)
auth_validation_total = Counter(
    'auth_validation_total',
    'Total de validações de autenticação por resultado',
    ['result']  # "success", "failure", "timeout", "error"
)
db_up = Gauge(
    'db_up',
    '1 se o PostgreSQL está acessível via pool, 0 se não'
)
auth_service_up = Gauge(
    'auth_service_up',
    '1 se o auth-service está acessível, 0 se não'
)
db_query_duration_seconds = Histogram(
    'db_query_duration_seconds',
    'Duração das queries ao PostgreSQL em segundos',
    ['operation']  # "create", "read", "update", "delete"
)

# --- Configuração ---
DATABASE_URL = os.getenv("DATABASE_URL")
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL")

if not DATABASE_URL or not AUTH_SERVICE_URL:
    log.critical("Erro: DATABASE_URL e AUTH_SERVICE_URL devem ser definidos.")
    sys.exit(1)

# --- Pool de Conexão com o Banco ---
try:
    pool = SimpleConnectionPool(1, 5, dsn=DATABASE_URL)
    log.info("Pool de conexões com o PostgreSQL (targeting) inicializado.")
    db_up.set(1)
except psycopg2.OperationalError as e:
    log.critical(f"Erro fatal ao conectar ao PostgreSQL: {e}")
    db_up.set(0)
    sys.exit(1)


def refresh_active_rules_gauge():
    """Atualiza o gauge de regras ativas consultando o banco."""
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM targeting_rules WHERE is_enabled = true")
        count = cur.fetchone()[0]
        rules_active_total.set(count)
    except Exception as e:
        log.error(f"Erro ao atualizar gauge de regras ativas: {e}")
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
            response = requests.get(
                validate_url, headers={"Authorization": auth_header}, timeout=3
            )

            if response.status_code != 200:
                log.warning(f"Falha na validação da chave (status: {response.status_code})")
                auth_validation_total.labels(result="failure").inc()
                return jsonify({"error": "Chave de API inválida"}), 401

            auth_validation_total.labels(result="success").inc()

        except requests.exceptions.Timeout:
            log.error("Timeout ao conectar com o auth-service")
            auth_validation_total.labels(result="timeout").inc()
            auth_service_up.set(0)
            return jsonify({"error": "Serviço de autenticação indisponível (timeout)"}), 504

        except requests.exceptions.RequestException as e:
            log.error(f"Erro ao conectar com o auth-service: {e}")
            auth_validation_total.labels(result="error").inc()
            auth_service_up.set(0)
            return jsonify({"error": "Serviço de autenticação indisponível"}), 503

        auth_service_up.set(1)
        return f(*args, **kwargs)

    return decorated


# --- Endpoints da API ---
@app.route('/health')
def health():
    return jsonify({"status": "ok"})


@app.route('/rules', methods=['POST'])
@require_auth
def create_rule():
    data = request.get_json()
    if not data or 'flag_name' not in data or 'rules' not in data:
        return jsonify({"error": "'flag_name' e 'rules' (JSON) são obrigatórios"}), 400

    flag_name = data['flag_name']
    rules_obj = data['rules']
    is_enabled = data.get('is_enabled', True)

    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="create").time():
            cur.execute(
                "INSERT INTO targeting_rules (flag_name, is_enabled, rules, created_at, updated_at) "
                "VALUES (%s, %s, %s, NOW(), NOW()) RETURNING *",
                (flag_name, is_enabled, Json(rules_obj))
            )
            new_rule = cur.fetchone()
        conn.commit()
        rules_created_total.inc()
        refresh_active_rules_gauge()
        log.info(f"Regra para '{flag_name}' criada com sucesso.")
        return jsonify(new_rule), 201
    except psycopg2.IntegrityError:
        if conn:
            conn.rollback()
        log.warning(f"Tentativa de criar regra duplicada: '{flag_name}'")
        return jsonify({"error": f"Regra para a flag '{flag_name}' já existe"}), 409
    except Exception as e:
        if conn:
            conn.rollback()
        db_up.set(0)
        log.error(f"Erro ao criar regra: {e}")
        return jsonify({"error": "Erro interno do servidor", "details": str(e)}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route('/rules/<string:flag_name>', methods=['GET'])
@require_auth
def get_rule(flag_name):
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="read").time():
            cur.execute("SELECT * FROM targeting_rules WHERE flag_name = %s", (flag_name,))
            rule = cur.fetchone()
        db_up.set(1)
        if not rule:
            return jsonify({"error": "Regra não encontrada"}), 404
        return jsonify(rule)
    except Exception as e:
        db_up.set(0)
        log.error(f"Erro ao buscar regra '{flag_name}': {e}")
        return jsonify({"error": "Erro interno do servidor", "details": str(e)}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route('/rules/<string:flag_name>', methods=['PUT'])
@require_auth
def update_rule(flag_name):
    data = request.get_json()
    if not data:
        return jsonify({"error": "Corpo da requisição obrigatório"}), 400

    fields = []
    values = []

    if 'rules' in data:
        fields.append("rules = %s")
        values.append(Json(data['rules']))
    if 'is_enabled' in data:
        fields.append("is_enabled = %s")
        values.append(data['is_enabled'])

    if not fields:
        return jsonify({"error": "Pelo menos um campo ('rules', 'is_enabled') é obrigatório"}), 400

    values.append(flag_name)
    query = f"UPDATE targeting_rules SET {', '.join(fields)}, updated_at = NOW() WHERE flag_name = %s RETURNING *"

    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        with db_query_duration_seconds.labels(operation="update").time():
            cur.execute(query, tuple(values))
            if cur.rowcount == 0:
                return jsonify({"error": "Regra não encontrada"}), 404
            updated_rule = cur.fetchone()
        conn.commit()
        rules_updated_total.inc()
        refresh_active_rules_gauge()
        log.info(f"Regra para '{flag_name}' atualizada com sucesso.")
        return jsonify(updated_rule), 200
    except Exception as e:
        if conn:
            conn.rollback()
        db_up.set(0)
        log.error(f"Erro ao atualizar regra '{flag_name}': {e}")
        return jsonify({"error": "Erro interno do servidor", "details": str(e)}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route('/rules/<string:flag_name>', methods=['DELETE'])
@require_auth
def delete_rule(flag_name):
    conn = None
    cur = None
    try:
        conn = pool.getconn()
        cur = conn.cursor()
        with db_query_duration_seconds.labels(operation="delete").time():
            cur.execute("DELETE FROM targeting_rules WHERE flag_name = %s", (flag_name,))
            if cur.rowcount == 0:
                return jsonify({"error": "Regra não encontrada"}), 404
        conn.commit()
        rules_deleted_total.inc()
        refresh_active_rules_gauge()
        log.info(f"Regra para '{flag_name}' deletada com sucesso.")
        return "", 204
    except Exception as e:
        if conn:
            conn.rollback()
        db_up.set(0)
        log.error(f"Erro ao deletar regra '{flag_name}': {e}")
        return jsonify({"error": "Erro interno do servidor", "details": str(e)}), 500
    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


if __name__ == '__main__':
    port = int(os.getenv("PORT", 8003))
    app.run(host='0.0.0.0', port=port, debug=False)  # nosec B104
