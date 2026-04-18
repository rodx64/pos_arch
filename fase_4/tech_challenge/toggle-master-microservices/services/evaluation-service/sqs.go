package main

import (
	"encoding/json"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
)

type EvaluationEvent struct {
	UserID    string    `json:"user_id"`
	FlagName  string    `json:"flag_name"`
	Result    bool      `json:"result"`
	Timestamp time.Time `json:"timestamp"`
}

func (a *App) sendEvaluationEvent(userID, flagName string, result bool) {
	if a.SqsSvc == nil || a.SqsQueueURL == "" {
		log.Printf("[SQS_DISABLED] Evento: User '%s', Flag '%s', Result '%t'", userID, flagName, result) // #nosec G706
		return
	}

	event := EvaluationEvent{
		UserID:    userID,
		FlagName:  flagName,
		Result:    result,
		Timestamp: time.Now().UTC(),
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
