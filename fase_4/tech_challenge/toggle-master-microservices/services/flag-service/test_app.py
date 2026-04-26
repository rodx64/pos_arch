import unittest
from unittest.mock import patch, MagicMock
import os
import sys
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
    """Cria mocks de conexão e cursor garantindo que não retornem MagicMocks na serialização."""
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

def make_auth_fail(mock_requests_get, status=403):
    resp = MagicMock()
    resp.status_code = status
    mock_requests_get.return_value = resp

AUTH_HEADER = {'Authorization': 'Bearer valid-key'}
JSON_CT = 'application/json'


class TestHealth(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()

    def test_health_returns_ok(self):
        resp = self.client.get('/health')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['status'], 'ok')


class TestAuthMiddleware(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        conn, cur = make_fresh_conn()
        cur.fetchall.return_value = []
        _mock_pool_instance.getconn.return_value = conn

    def test_missing_auth_header_returns_401(self):
        resp = self.client.get('/flags')
        self.assertEqual(resp.status_code, 401)
        self.assertIn('Authorization', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_invalid_api_key_returns_401(self, mock_requests_get):
        make_auth_fail(mock_requests_get)
        resp = self.client.get('/flags', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 401)
        self.assertIn('inválida', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_auth_timeout_returns_504(self, mock_requests_get):
        import requests as req
        mock_requests_get.side_effect = req.exceptions.Timeout()
        resp = self.client.get('/flags', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 504)

class TestCreateFlag(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_create_flag_success(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchone.return_value = {
            'id': 1, 'name': 'feature_x', 'description': 'Test flag',
            'is_enabled': False, 'created_at': '2026-01-01T00:00:00',
            'updated_at': '2026-01-01T00:00:00',
        }

        resp = self.client.post(
            '/flags',
            data=json.dumps({'name': 'feature_x', 'description': 'Test flag'}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.get_json()['name'], 'feature_x')

    @patch('app.requests.get')
    def test_create_flag_duplicate_returns_409(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.execute.side_effect = app.psycopg2.IntegrityError()

        resp = self.client.post(
            '/flags',
            data=json.dumps({'name': 'existing_flag'}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 409)
        self.conn.rollback.assert_called_once()


class TestGetFlags(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_get_flags_returns_list(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchall.return_value = [
            {'id': 1, 'name': 'flag_a', 'is_enabled': True},
            {'id': 2, 'name': 'flag_b', 'is_enabled': False},
        ]

        resp = self.client.get('/flags', headers=AUTH_HEADER)

        self.assertEqual(resp.status_code, 200)
        self.assertIsInstance(resp.get_json(), list)

class TestUpdateFlag(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_update_is_enabled_success(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 1
        self.cur.fetchone.return_value = {'id': 1, 'name': 'feature_x', 'is_enabled': True}

        resp = self.client.put(
            '/flags/feature_x',
            data=json.dumps({'is_enabled': True}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 200)
        self.conn.commit.assert_called_once()


class TestDeleteFlag(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_delete_flag_success_returns_204(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 1
        resp = self.client.delete('/flags/feature_x', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 204)
        self.conn.commit.assert_called_once()

if __name__ == '__main__':
    unittest.main()
