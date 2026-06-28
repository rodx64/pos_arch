import os
import unittest
from unittest.mock import patch, MagicMock
import time
import json

os.environ["AWS_REGION"] = "us-east-1"
os.environ["AWS_SQS_URL"] = "http://fake-sqs"
os.environ["AWS_DYNAMODB_TABLE"] = "fake-table"
os.environ["ENVIRONMENT"] = "local"


import app  # noqa: E402


class TestProcessMessage(unittest.TestCase):

    @patch('app.dynamodb_client')
    @patch('app.sqs_client')
    @patch('app.tracer')
    def test_process_message_success(self, mock_tracer, mock_sqs, mock_dynamo):
        mock_span = MagicMock()
        mock_tracer.start_as_current_span.return_value.__enter__.return_value = mock_span

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

        mock_dynamo.put_item.assert_called_once()
        mock_sqs.delete_message.assert_called_once_with(
            QueueUrl=app.SQS_QUEUE_URL,
            ReceiptHandle='handle-123'
        )
        mock_tracer.start_as_current_span.assert_called_with("sqs.process_message")

    @patch('app.dynamodb_client')
    @patch('app.sqs_client')
    @patch('app.tracer')
    def test_process_message_bad_json(self, mock_tracer, mock_sqs, mock_dynamo):
        mock_span = MagicMock()
        mock_tracer.start_as_current_span.return_value.__enter__.return_value = mock_span

        message = {
            'MessageId': '124',
            'ReceiptHandle': 'handle-124',
            'Body': 'INVALID_JSON'
        }

        app.process_message(message)

        mock_dynamo.put_item.assert_not_called()
        mock_sqs.delete_message.assert_not_called()
        mock_span.set_status.assert_called_once()


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
