package main

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
	"go.opentelemetry.io/otel/trace"
)

type EvaluationEvent struct {
	UserID    string    `json:"user_id"`
	FlagName  string    `json:"flag_name"`
	Result    bool      `json:"result"`
	Timestamp time.Time `json:"timestamp"`
	TraceID   string    `json:"trace_id"`
}

func (a *App) sendEvaluationEvent(ctx context.Context, userID, flagName string, result bool) {
	if a.SqsSvc == nil || a.SqsQueueURL == "" {
		log.Printf("[SQS_DISABLED] Evento: User '%s', Flag '%s', Result '%t'", userID, flagName, result) // #nosec G706
		return
	}

	span := trace.SpanFromContext(ctx)
	traceID := span.SpanContext().TraceID().String()

	event := EvaluationEvent{
		UserID:    userID,
		FlagName:  flagName,
		Result:    result,
		Timestamp: time.Now().UTC(),
		TraceID:   traceID,
	}

	body, err := json.Marshal(event)
	if err != nil {
		log.Printf("Erro ao serializar evento SQS: %v", err)
		a.Metrics.sqsEventsFailedTotal.Inc() // métrica: falha na serialização
		return
	}

	_, err = a.SqsSvc.SendMessage(&sqs.SendMessageInput{
		MessageBody: aws.String(string(body)),
		QueueUrl:    aws.String(a.SqsQueueURL),
	})

	if err != nil {
		log.Printf("Erro ao enviar mensagem para SQS: %v", err)
		a.Metrics.sqsEventsFailedTotal.Inc() // métrica: falha no envio
	} else {
		log.Printf("Evento de avaliação enviado para SQS (Flag: %s)", flagName) // #nosec G706
		a.Metrics.sqsEventsSentTotal.Inc()                                      // métrica: envio ok
	}
}
