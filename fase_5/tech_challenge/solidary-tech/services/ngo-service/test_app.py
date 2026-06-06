import json
import sys
import unittest
from unittest.mock import MagicMock, patch

if 'app' in sys.modules:
    del sys.modules['app']

_mock_pool_instance = MagicMock()

with patch('psycopg2.pool.SimpleConnectionPool', return_value=_mock_pool_instance):
    import app


def make_fresh_conn():
    cur = MagicMock()
    conn = MagicMock()
    conn.cursor.return_value.__enter__.return_value = cur
    return conn, cur


class TestHealthEndpoint(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()

    def test_health_returns_ok(self):
        resp = self.client.get('/ngos/health')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json(), {'status': 'ok', 'service': 'ngo-service'})


class TestCreateNgo(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        app.pool = MagicMock()
        app.pool.getconn.return_value = self.conn

    def tearDown(self):
        app.pool = _mock_pool_instance

    def test_create_ngo_returns_400_when_body_is_missing(self):
        resp = self.client.post('/ngos', data=json.dumps({}), content_type='application/json')
        self.assertEqual(resp.status_code, 400)
        self.assertIn('Campos obrigatórios ausentes', resp.get_json()['error'])

    def test_create_ngo_returns_400_when_some_fields_are_missing(self):
        payload = {'name': 'Test ONG', 'email': 'test@example.com'}
        resp = self.client.post('/ngos', data=json.dumps(payload), content_type='application/json')
        self.assertEqual(resp.status_code, 400)
        self.assertIn('Campos obrigatórios ausentes', resp.get_json()['error'])

    def test_create_ngo_success(self):
        self.cur.fetchone.return_value = {
            'id': 1,
            'name': 'Test ONG',
            'email': 'test@example.com',
            'cause': 'Educação',
            'city': 'São Paulo'
        }

        resp = self.client.post(
            '/ngos',
            data=json.dumps({
                'name': 'Test ONG',
                'email': 'test@example.com',
                'cause': 'Educação',
                'city': 'São Paulo'
            }),
            content_type='application/json'
        )

        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.get_json()['name'], 'Test ONG')
        self.cur.execute.assert_called_once()
        self.conn.commit.assert_called_once()
        app.pool.putconn.assert_called_once_with(self.conn)

    def test_create_ngo_duplicate_email_returns_409(self):
        self.cur.execute.side_effect = app.psycopg2.IntegrityError()

        resp = self.client.post(
            '/ngos',
            data=json.dumps({
                'name': 'Test ONG',
                'email': 'duplicate@example.com',
                'cause': 'Saúde',
                'city': 'Rio'
            }),
            content_type='application/json'
        )

        self.assertEqual(resp.status_code, 409)
        self.assertEqual(resp.get_json()['error'], 'E-mail já cadastrado')
        self.conn.rollback.assert_called_once()
        app.pool.putconn.assert_called_once_with(self.conn)

    def test_create_ngo_internal_error_returns_500(self):
        self.cur.execute.side_effect = Exception('fail')

        resp = self.client.post(
            '/ngos',
            data=json.dumps({
                'name': 'Test ONG',
                'email': 'error@example.com',
                'cause': 'Meio ambiente',
                'city': 'Belém'
            }),
            content_type='application/json'
        )

        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.get_json()['error'], 'Erro interno')
        self.conn.rollback.assert_called_once()
        app.pool.putconn.assert_called_once_with(self.conn)


class TestGetNgos(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.conn, self.cur = make_fresh_conn()
        app.pool = MagicMock()
        app.pool.getconn.return_value = self.conn

    def tearDown(self):
        app.pool = _mock_pool_instance

    def test_get_ngos_returns_list(self):
        self.cur.fetchall.return_value = [
            {'id': 1, 'name': 'Test ONG', 'email': 'test@example.com', 'cause': 'Educação', 'city': 'São Paulo'},
            {'id': 2, 'name': 'Another ONG', 'email': 'another@example.com', 'cause': 'Saúde', 'city': 'Fortaleza'}
        ]

        resp = self.client.get('/ngos')

        self.assertEqual(resp.status_code, 200)
        self.assertIsInstance(resp.get_json(), list)
        self.assertEqual(len(resp.get_json()), 2)
        app.pool.putconn.assert_called_once_with(self.conn)

    def test_get_ngos_internal_error_returns_500(self):
        self.cur.execute.side_effect = Exception('fail')

        resp = self.client.get('/ngos')

        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.get_json()['error'], 'Erro interno')
        app.pool.putconn.assert_called_once_with(self.conn)


class TestDatabaseInitialization(unittest.TestCase):

    @patch('app.SimpleConnectionPool', return_value=_mock_pool_instance)
    def test_init_db_pool_uses_provided_url(self, mock_pool_class):
        pool = app.init_db_pool('postgres://user:pass@localhost:5432/db')
        self.assertIs(pool, _mock_pool_instance)
        mock_pool_class.assert_called_once_with(1, 10, dsn='postgres://user:pass@localhost:5432/db')

    def test_init_db_pool_without_database_url_raises_runtime_error(self):
        with self.assertRaises(RuntimeError):
            app.init_db_pool('')


if __name__ == '__main__':
    unittest.main()
