package main

import (
	"bytes"
	"log"
	"os"
	"strings"
	"testing"
)

func TestSendEvaluationEvent_SQSDisabled_NilSvc(t *testing.T) {
	app := &App{
		SqsSvc:      nil,
		SqsQueueURL: "",
	}

	var buf bytes.Buffer
	log.SetOutput(&buf)
	defer log.SetOutput(os.Stderr)

	app.sendEvaluationEvent("user1", "test-flag", true)

	output := buf.String()
	if !strings.Contains(output, "[SQS_DISABLED]") {
		t.Errorf("esperado log com [SQS_DISABLED], obteve: %s", output)
	}
	if !strings.Contains(output, "user1") {
		t.Errorf("esperado user_id no log, obteve: %s", output)
	}
	if !strings.Contains(output, "test-flag") {
		t.Errorf("esperado flag_name no log, obteve: %s", output)
	}
}

func TestSendEvaluationEvent_SQSDisabled_EmptyURL(t *testing.T) {
	app := &App{
		SqsSvc:      nil,
		SqsQueueURL: "",
	}

	var buf bytes.Buffer
	log.SetOutput(&buf)
	defer log.SetOutput(os.Stderr)

	app.sendEvaluationEvent("user2", "flag-2", false)

	output := buf.String()
	if !strings.Contains(output, "[SQS_DISABLED]") {
		t.Errorf("esperado log com [SQS_DISABLED], obteve: %s", output)
	}
	if !strings.Contains(output, "false") {
		t.Errorf("esperado result 'false' no log, obteve: %s", output)
	}
}

func TestSendEvaluationEvent_SQSDisabled_ResultTrue(t *testing.T) {
	app := &App{
		SqsSvc:      nil,
		SqsQueueURL: "",
	}

	var buf bytes.Buffer
	log.SetOutput(&buf)
	defer log.SetOutput(os.Stderr)

	app.sendEvaluationEvent("user3", "flag-3", true)

	output := buf.String()
	if !strings.Contains(output, "true") {
		t.Errorf("esperado result 'true' no log, obteve: %s", output)
	}
}
