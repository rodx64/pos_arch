# Atalhos de execução Local


## SQS
```shell
  aws --endpoint-url=http://localhost:4566 sqs list-queues
```

```shell
    aws --endpoint-url=http://localhost:4566 sqs send-message \
      --queue-url http://localhost:4566/000000000000/toggle-analytics-queue \
      --message-body '{"user_id":"user_001","flag_name":"feature_test","result":true,"timestamp":"2025-11-08T03:15:00Z"}'
````

## DYNAMODB

### Listar tabelas
```shell
    aws --endpoint-url=http://localhost:4566 dynamodb list-tables   
```

### Status Table (DESCRIBE-TABLE)
```shell
    aws --endpoint-url=http://localhost:4566 dynamodb describe-table \
      --table-name analytics_events
```

### Inserir Item (PUT-ITEM)
```shell
    aws --endpoint-url=http://localhost:4566 dynamodb put-item \
      --table-name analytics_events  \
      --item '{"id": {"S": "u1"}, "name": {"S": "Alice"}, "age": {"N": "30"}}'
```

### Obter Item (GET-ITEM)
```shell
    aws --endpoint-url=http://localhost:4566 dynamodb get-item \
      --table-name analytics_events \
      --key '{"id": {"S": "u1"}}'
```

### Listar todos Itens (SCAN)
```shell
    aws --endpoint-url=http://localhost:4566 dynamodb scan \
      --table-name analytics_events
```

### Deletar item pela key do projeto (event_id)
```shell
    aws --endpoint-url=http://localhost:4566 dynamodb delete-item \
      --table-name analytics_events \
      --key '{"event_id": {"S": "123e4567-e89b-12d3-a456-426614174000"}}'
```