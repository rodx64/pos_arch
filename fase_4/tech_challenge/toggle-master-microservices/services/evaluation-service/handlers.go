package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type EvaluationResponse struct {
	FlagName string `json:"flag_name"`
	UserID   string `json:"user_id"`
	Result   bool   `json:"result"`
}

func (a *App) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(map[string]string{"status": "ok"}); err != nil {
		log.Printf("Erro ao encodar resposta de health: %v", err)
	}
}

func (a *App) evaluationHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	ctx := r.Context()

	userID := r.URL.Query().Get("user_id")
	flagName := r.URL.Query().Get("flag_name")

	if userID == "" || flagName == "" {
		http.Error(w, `{"error": "user_id e flag_name são obrigatórios"}`, http.StatusBadRequest)
		return
	}

	result, err := a.getDecision(ctx, userID, flagName)
	if err != nil {
		if _, ok := err.(*NotFoundError); ok {
			result = false
			// flag não encontrada conta como resultado false, não erro
			a.Metrics.evaluationsTotal.WithLabelValues(flagName, "false").Inc()
		} else {
			log.Printf("Erro ao avaliar flag '%s': %v", flagName, err) // #nosec G706
			a.Metrics.evaluationsTotal.WithLabelValues(flagName, "error").Inc()
			http.Error(w, `{"error": "Erro interno ao avaliar a flag"}`, http.StatusBadGateway)
			return
		}
	} else {
		a.Metrics.evaluationsTotal.WithLabelValues(flagName, fmt.Sprintf("%t", result)).Inc()
	}

	go a.sendEvaluationEvent(ctx, userID, flagName, result)

	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(EvaluationResponse{
		FlagName: flagName,
		UserID:   userID,
		Result:   result,
	}); err != nil {
		log.Printf("Erro ao encodar resposta de avaliação: %v", err)
	}
}
