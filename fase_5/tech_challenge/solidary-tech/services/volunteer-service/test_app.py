import json
import sys
import unittest
from unittest.mock import MagicMock

if 'app' in sys.modules:
    del sys.modules['app']

import app


class TestHealthEndpoint(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()

    def test_health_returns_ok(self):
        resp = self.client.get('/volunteers/health')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json(), {'status': 'ok', 'service': 'volunteer-service'})


class TestRegisterVolunteer(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.table = MagicMock()
        app.table = self.table

    def test_register_volunteer_missing_fields_returns_400(self):
        resp = self.client.post(
            '/volunteers',
            data=json.dumps({'name': 'Alice'}),
            content_type='application/json'
        )
        self.assertEqual(resp.status_code, 400)
        self.assertIn('Campos obrigatórios ausentes', resp.get_json()['error'])

    def test_register_volunteer_success(self):
        self.table.put_item.return_value = {'ResponseMetadata': {'HTTPStatusCode': 200}}

        resp = self.client.post(
            '/volunteers',
            data=json.dumps({'name': 'Alice', 'email': 'alice@example.com', 'ngo_id': 42}),
            content_type='application/json'
        )

        self.assertEqual(resp.status_code, 201)
        data = resp.get_json()
        self.assertEqual(data['name'], 'Alice')
        self.assertEqual(data['email'], 'alice@example.com')
        self.assertEqual(data['ngo_id'], 42)
        self.assertIn('volunteer_id', data)
        self.assertIn('registered_at', data)
        self.table.put_item.assert_called_once()

    def test_register_volunteer_internal_error_returns_500(self):
        self.table.put_item.side_effect = Exception('fail')

        resp = self.client.post(
            '/volunteers',
            data=json.dumps({'name': 'Alice', 'email': 'alice@example.com', 'ngo_id': 42}),
            content_type='application/json'
        )

        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.get_json()['error'], 'Erro interno ao processar dados')


class TestGetVolunteersByNgo(unittest.TestCase):

    def setUp(self):
        self.client = app.app.test_client()
        self.table = MagicMock()
        app.table = self.table

    def test_get_volunteers_by_ngo_returns_items(self):
        self.table.scan.return_value = {
            'Items': [
                {'volunteer_id': '1', 'name': 'Alice', 'email': 'alice@example.com', 'ngo_id': 42}
            ]
        }

        resp = self.client.get('/volunteers/42')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json(), self.table.scan.return_value['Items'])

    def test_get_volunteers_by_ngo_internal_error_returns_500(self):
        self.table.scan.side_effect = Exception('fail')

        resp = self.client.get('/volunteers/42')
        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.get_json()['error'], 'Erro interno')


if __name__ == '__main__':
    unittest.main()
