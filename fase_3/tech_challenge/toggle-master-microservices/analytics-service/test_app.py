# test_app.py
import unittest
from unittest.mock import patch
import time
import json

import app

class TestProcessMessage(unittest.TestCase):


    @patch('app.dynamodb_client')
    @patch('app.sqs_client')
    def test_process_message_success(self, mock_sqs, mock_dynamo):
        # Simula uma mensagem SQS válida
        message = {
            'MessageId': '123',
            'ReceiptHandle': 'handle-123',
            'Body': json.dumps({
                'user_id': 'u1',
                'flag_name': 'feature_x',
                'result': True,
                'timestamp': '2026-03-14T12:00:00Z'
            })
        }

        app.process_message(message)

        # Verifica se put_item foi chamado no DynamoDB
        mock_dynamo.put_item.assert_called_once()
        # Verifica se delete_message foi chamado no SQS
        mock_sqs.delete_message.assert_called_once_with(
            QueueUrl=app.SQS_QUEUE_URL,
            ReceiptHandle='handle-123'
        )

    @patch('app.dynamodb_client')
    @patch('app.sqs_client')
    def test_process_message_bad_json(self, mock_sqs, mock_dynamo):
        # Mensagem com JSON inválido
        message = {
            'MessageId': '124',
            'ReceiptHandle': 'handle-124',
            'Body': 'INVALID_JSON'
        }

        app.process_message(message)

        # Não deve tentar inserir no DynamoDB
        mock_dynamo.put_item.assert_not_called()
        # Não deve deletar mensagem inválida
        mock_sqs.delete_message.assert_not_called()


class TestHealthChecks(unittest.TestCase):
    def setUp(self):
        # Test client do Flask
        self.client = app.app.test_client()
        # Reseta estado
        app.worker_started = True
        app.last_heartbeat = time.time()

    def test_health_startup_started(self):
        app.worker_started = True
        resp = self.client.get('/health/startup')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json['status'], 'started')

    def test_health_startup_not_started(self):
        app.worker_started = False
        resp = self.client.get('/health/startup')
        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.json['status'], 'not-started')

    def test_health_live_alive(self):
        app.last_heartbeat = time.time()
        resp = self.client.get('/health/live')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json['status'], 'alive')

    def test_health_live_dead(self):
        app.last_heartbeat = time.time() - app.HEARTBEAT_INTERVAL - 1
        resp = self.client.get('/health/live')
        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.json['status'], 'dead')

    def test_health_ready_ready(self):
        app.worker_started = True
        app.last_heartbeat = time.time()
        resp = self.client.get('/health/ready')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json['status'], 'ready')

    def test_health_ready_not_ready_due_to_heartbeat(self):
        app.worker_started = True
        app.last_heartbeat = time.time() - app.HEARTBEAT_INTERVAL - 1
        resp = self.client.get('/health/ready')
        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.json['status'], 'not-ready')

    def test_health_ready_not_ready_due_to_worker(self):
        app.worker_started = False
        app.last_heartbeat = time.time()
        resp = self.client.get('/health/ready')
        self.assertEqual(resp.status_code, 500)
        self.assertEqual(resp.json['status'], 'not-ready')


class TestWorkerHeartbeat(unittest.TestCase):
    def test_worker_heartbeat_updates_last_heartbeat(self):
        old_heartbeat = app.last_heartbeat
        app.worker_heartbeat()
        self.assertGreater(app.last_heartbeat, old_heartbeat)


if __name__ == '__main__':
    unittest.main()
