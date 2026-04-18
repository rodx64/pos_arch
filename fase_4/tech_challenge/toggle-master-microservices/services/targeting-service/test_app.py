import unittest
from unittest.mock import patch, MagicMock
import json
import sys


if 'app' in sys.modules:
    del sys.modules['app']

_mock_pool_instance = MagicMock()

with patch('psycopg2.pool.SimpleConnectionPool', return_value=_mock_pool_instance):
    import app


def make_fresh_conn():
    """Cria um par (conn, cur) limpo para cada teste."""
    cur = MagicMock()
    conn = MagicMock()
    conn.cursor.return_value = cur
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

SAMPLE_RULES = {"attribute": "country", "operator": "eq", "value": "BR"}


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
        cur.fetchone.return_value = {'flag_name': 'feature_x', 'is_enabled': True, 'rules': SAMPLE_RULES}
        _mock_pool_instance.getconn.return_value = conn

    def test_missing_auth_header_returns_401(self):
        resp = self.client.get('/rules/feature_x')
        self.assertEqual(resp.status_code, 401)
        self.assertIn('Authorization', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_invalid_api_key_returns_401(self, mock_requests_get):
        make_auth_fail(mock_requests_get)
        resp = self.client.get('/rules/feature_x', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 401)
        self.assertIn('inválida', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_auth_timeout_returns_504(self, mock_requests_get):
        import requests as req
        mock_requests_get.side_effect = req.exceptions.Timeout()
        resp = self.client.get('/rules/feature_x', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 504)

    @patch('app.requests.get')
    def test_auth_connection_error_returns_503(self, mock_requests_get):
        import requests as req
        mock_requests_get.side_effect = req.exceptions.RequestException('conn error')
        resp = self.client.get('/rules/feature_x', headers=AUTH_HEADER)
        self.assertEqual(resp.status_code, 503)


class TestCreateRule(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_create_rule_success(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchone.return_value = {
            'id': 1,
            'flag_name': 'feature_x',
            'is_enabled': True,
            'rules': SAMPLE_RULES,
            'created_at': '2026-01-01T00:00:00',
            'updated_at': '2026-01-01T00:00:00',
        }

        resp = self.client.post(
            '/rules',
            data=json.dumps({'flag_name': 'feature_x', 'rules': SAMPLE_RULES}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.get_json()['flag_name'], 'feature_x')
        self.cur.execute.assert_called_once()
        self.conn.commit.assert_called_once()

    @patch('app.requests.get')
    def test_create_rule_default_is_enabled_true(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchone.return_value = {
            'id': 2, 'flag_name': 'flag_b', 'is_enabled': True,
            'rules': SAMPLE_RULES, 'created_at': '2026-01-01T00:00:00',
            'updated_at': '2026-01-01T00:00:00',
        }

        resp = self.client.post(
            '/rules',
            data=json.dumps({'flag_name': 'flag_b', 'rules': SAMPLE_RULES}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 201)
        self.assertTrue(resp.get_json()['is_enabled'])

    @patch('app.requests.get')
    def test_create_rule_missing_flag_name_returns_400(self, mock_requests_get):
        make_auth_ok(mock_requests_get)

        resp = self.client.post(
            '/rules',
            data=json.dumps({'rules': SAMPLE_RULES}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 400)
        self.assertIn('flag_name', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_create_rule_missing_rules_returns_400(self, mock_requests_get):
        make_auth_ok(mock_requests_get)

        resp = self.client.post(
            '/rules',
            data=json.dumps({'flag_name': 'feature_x'}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 400)
        self.assertIn('rules', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_create_rule_empty_body_returns_400(self, mock_requests_get):
        make_auth_ok(mock_requests_get)

        resp = self.client.post(
            '/rules',
            data=json.dumps({}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 400)

    @patch('app.requests.get')
    def test_create_rule_duplicate_returns_409(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.execute.side_effect = app.psycopg2.IntegrityError()

        resp = self.client.post(
            '/rules',
            data=json.dumps({'flag_name': 'existing_flag', 'rules': SAMPLE_RULES}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 409)
        self.assertIn('já existe', resp.get_json()['error'])
        self.conn.rollback.assert_called_once()


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
        self.assertEqual(resp.get_json()['flag_name'], 'feature_x')

    @patch('app.requests.get')
    def test_get_rule_not_found_returns_404(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.fetchone.return_value = None

        resp = self.client.get('/rules/nonexistent', headers=AUTH_HEADER)

        self.assertEqual(resp.status_code, 404)
        self.assertIn('não encontrada', resp.get_json()['error'])


class TestUpdateRule(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_update_rules_success(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 1
        new_rules = {"attribute": "plan", "operator": "eq", "value": "premium"}
        self.cur.fetchone.return_value = {
            'id': 1, 'flag_name': 'feature_x', 'is_enabled': True, 'rules': new_rules
        }

        resp = self.client.put(
            '/rules/feature_x',
            data=json.dumps({'rules': new_rules}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['rules'], new_rules)
        self.conn.commit.assert_called_once()

    @patch('app.requests.get')
    def test_update_is_enabled_success(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 1
        self.cur.fetchone.return_value = {
            'id': 1, 'flag_name': 'feature_x', 'is_enabled': False, 'rules': SAMPLE_RULES
        }

        resp = self.client.put(
            '/rules/feature_x',
            data=json.dumps({'is_enabled': False}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 200)
        self.assertFalse(resp.get_json()['is_enabled'])

    @patch('app.requests.get')
    def test_update_rule_not_found_returns_404(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 0

        resp = self.client.put(
            '/rules/ghost_flag',
            data=json.dumps({'is_enabled': False}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 404)

    @patch('app.requests.get')
    def test_update_rule_no_valid_fields_returns_400(self, mock_requests_get):
        make_auth_ok(mock_requests_get)

        resp = self.client.put(
            '/rules/feature_x',
            data=json.dumps({'unknown_field': 'value'}),
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 400)
        self.assertIn('obrigatório', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_update_rule_no_body_returns_400(self, mock_requests_get):
        make_auth_ok(mock_requests_get)

        resp = self.client.put(
            '/rules/feature_x',
            data='{}',
            content_type=JSON_CT,
            headers=AUTH_HEADER
        )

        self.assertEqual(resp.status_code, 400)


class TestDeleteRule(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        _mock_pool_instance.getconn.return_value = self.conn

    @patch('app.requests.get')
    def test_delete_rule_success_returns_204(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 1

        resp = self.client.delete('/rules/feature_x', headers=AUTH_HEADER)

        self.assertEqual(resp.status_code, 204)
        self.assertEqual(resp.data, b'')
        self.conn.commit.assert_called_once()

    @patch('app.requests.get')
    def test_delete_rule_not_found_returns_404(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.rowcount = 0

        resp = self.client.delete('/rules/nonexistent', headers=AUTH_HEADER)

        self.assertEqual(resp.status_code, 404)
        self.assertIn('não encontrada', resp.get_json()['error'])

    @patch('app.requests.get')
    def test_delete_rule_db_error_returns_500(self, mock_requests_get):
        make_auth_ok(mock_requests_get)
        self.cur.execute.side_effect = Exception('db error')

        resp = self.client.delete('/rules/feature_x', headers=AUTH_HEADER)

        self.assertEqual(resp.status_code, 500)
        self.conn.rollback.assert_called_once()


if __name__ == '__main__':
    unittest.main()
