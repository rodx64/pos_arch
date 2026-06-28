import unittest
from unittest.mock import patch, MagicMock
import os
import json

os.environ["DATABASE_URL"] = "postgresql://user:pass@localhost:5432/db"
os.environ["AUTH_SERVICE_URL"] = "http://auth-service"
os.environ["OTEL_PYTHON_DISABLED"] = "true"

_mock_pool_instance = MagicMock()

with patch('psycopg2.pool.SimpleConnectionPool', return_value=_mock_pool_instance), \
     patch('opentelemetry.exporter.otlp.proto.grpc.trace_exporter.OTLPSpanExporter', MagicMock()), \
     patch('opentelemetry.instrumentation.flask.FlaskInstrumentor.instrument_app', MagicMock()), \
     patch('opentelemetry.instrumentation.requests.RequestsInstrumentor.instrument', MagicMock()), \
     patch('opentelemetry.instrumentation.psycopg2.Psycopg2Instrumentor.instrument', MagicMock()):

    import app


def make_fresh_conn():
    """Cria um par (conn, cur) limpo para cada teste."""
    cur = MagicMock()
    conn = MagicMock()
    conn.cursor.return_value = cur
    cur.fetchall.return_value = []
    cur.fetchone.return_value = None
    return conn, cur


def make_auth_ok(mock_requests_get):
    resp = MagicMock()
    resp.status_code = 200
    mock_requests_get.return_value = resp


AUTH_HEADER = {'Authorization': 'Bearer valid-key'}
JSON_CT = 'application/json'
SAMPLE_RULES = {"attribute": "country", "operator": "eq", "value": "BR"}


class TestHealth(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()

    def test_health_returns_ok(self):
        resp = self.client.get('/health')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['status'], 'ok')


class TestCreateRule(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_create_rule_success(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchone.return_value = {
            'id': 1, 'flag_name': 'feature_x', 'is_enabled': True, 'rules': SAMPLE_RULES
        }
        resp = self.client.post(
            '/rules',
            data=json.dumps({'flag_name': 'feature_x', 'rules': SAMPLE_RULES}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.get_json()['flag_name'], 'feature_x')


class TestGetRule(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_get_rule_found(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchone.return_value = {
            'id': 1, 'flag_name': 'feature_x', 'is_enabled': True, 'rules': SAMPLE_RULES
        }
        resp = self.client.get('/rules/feature_x', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 200)


if __name__ == '__main__':
    unittest.main()
