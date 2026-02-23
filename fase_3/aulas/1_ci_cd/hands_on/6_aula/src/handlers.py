import json
import os
from datetime import datetime

def response(status_code, body):
    """Helper para criar resposta Lambda"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, default=str)
    }

def hello(event, context):
    """GET / - Hello World"""
    return response(200, {
        'message': 'Hello from FIAP Serverless!',
        'environment': os.environ.get('ENVIRONMENT', 'dev')
    })

def health(event, context):
    """GET /health - Health check"""
    return response(200, {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': os.environ.get('ENVIRONMENT', 'dev')
    })

def info(event, context):
    """GET /info - Info da aplicação"""
    return response(200, {
        'app': 'FIAP Serverless API',
        'version': '1.0.0',
        'environment': os.environ.get('ENVIRONMENT', 'dev'),
        'endpoints': [
            'GET / - Hello',
            'GET /health - Health check',
            'GET /info - Info'
        ]
    })
