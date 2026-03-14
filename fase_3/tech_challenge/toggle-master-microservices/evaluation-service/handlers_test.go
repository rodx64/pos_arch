package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-redis/redismock/v8"
)

// --- healthHandler Tests ---

func TestHealthHandler_ReturnsOK(t *testing.T) {
	app := newTestApp()
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	app.healthHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}

	var resp map[string]string
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}
	if resp["status"] != "ok" {
		t.Errorf("status esperado 'ok', obteve '%s'", resp["status"])
	}

	contentType := w.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("Content-Type esperado 'application/json', obteve '%s'", contentType)
	}
}

// --- evaluationHandler Tests ---

func TestEvaluationHandler_MissingUserID(t *testing.T) {
	app := newTestApp()
	req := httptest.NewRequest(http.MethodGet, "/evaluate?flag_name=test", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("status esperado %d, obteve %d", http.StatusBadRequest, w.Code)
	}
}

func TestEvaluationHandler_MissingFlagName(t *testing.T) {
	app := newTestApp()
	req := httptest.NewRequest(http.MethodGet, "/evaluate?user_id=user1", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("status esperado %d, obteve %d", http.StatusBadRequest, w.Code)
	}
}

func TestEvaluationHandler_MissingBothParams(t *testing.T) {
	app := newTestApp()
	req := httptest.NewRequest(http.MethodGet, "/evaluate", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("status esperado %d, obteve %d", http.StatusBadRequest, w.Code)
	}
}

func TestEvaluationHandler_Success_FlagEnabled(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Flag{Name: "my-flag", IsEnabled: true})
	}))
	defer flagServer.Close()

	ruleServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer ruleServer.Close()

	app := &App{
		RedisClient:         db,
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: ruleServer.URL,
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}

	expectedInfo := CombinedFlagInfo{
		Flag: &Flag{Name: "my-flag", IsEnabled: true},
		Rule: nil,
	}
	expectedJSON, _ := json.Marshal(expectedInfo)

	redisMock.ExpectGet("flag_info:my-flag").RedisNil()
	redisMock.ExpectSet("flag_info:my-flag", expectedJSON, CACHE_TTL).SetVal("OK")

	req := httptest.NewRequest(http.MethodGet, "/evaluate?user_id=user1&flag_name=my-flag", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}

	var resp EvaluationResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}
	if resp.FlagName != "my-flag" {
		t.Errorf("flag_name esperado 'my-flag', obteve '%s'", resp.FlagName)
	}
	if resp.UserID != "user1" {
		t.Errorf("user_id esperado 'user1', obteve '%s'", resp.UserID)
	}
	if resp.Result != true {
		t.Error("esperado result=true para flag habilitada sem regra")
	}
}

func TestEvaluationHandler_FlagNotFound_ReturnsFalse(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer flagServer.Close()

	ruleServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer ruleServer.Close()

	app := &App{
		RedisClient:         db,
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: ruleServer.URL,
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}

	redisMock.ExpectGet("flag_info:nonexistent").RedisNil()

	req := httptest.NewRequest(http.MethodGet, "/evaluate?user_id=user1&flag_name=nonexistent", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}

	var resp EvaluationResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}
	if resp.Result != false {
		t.Error("esperado result=false para flag não encontrada")
	}
}

func TestEvaluationHandler_ServiceError_Returns502(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer flagServer.Close()

	ruleServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(TargetingRule{FlagName: "err-flag"})
	}))
	defer ruleServer.Close()

	app := &App{
		RedisClient:         db,
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: ruleServer.URL,
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}

	redisMock.ExpectGet("flag_info:err-flag").RedisNil()

	req := httptest.NewRequest(http.MethodGet, "/evaluate?user_id=user1&flag_name=err-flag", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusBadGateway {
		t.Errorf("status esperado %d, obteve %d", http.StatusBadGateway, w.Code)
	}
}

func TestEvaluationHandler_CacheHit(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	info := CombinedFlagInfo{
		Flag: &Flag{Name: "cached", IsEnabled: true},
		Rule: nil,
	}
	jsonData, _ := json.Marshal(info)

	app := &App{
		RedisClient: db,
		HttpClient:  &http.Client{Timeout: 5 * time.Second},
	}

	redisMock.ExpectGet("flag_info:cached").SetVal(string(jsonData))

	req := httptest.NewRequest(http.MethodGet, "/evaluate?user_id=user1&flag_name=cached", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}

	var resp EvaluationResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}
	if resp.Result != true {
		t.Error("esperado result=true para flag em cache habilitada")
	}
}
