package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-redis/redismock/v8"
)

func TestGetDeterministicBucket_IsDeterministic(t *testing.T) {
	input := "user123my-flag"
	b1 := getDeterministicBucket(input)
	b2 := getDeterministicBucket(input)

	if b1 != b2 {
		t.Errorf("bucket não é determinístico: %d != %d", b1, b2)
	}
}

func TestGetDeterministicBucket_Range0to99(t *testing.T) {
	for i := 0; i < 1000; i++ {
		input := fmt.Sprintf("user-%d-flag-%d", i, i*7)
		bucket := getDeterministicBucket(input)
		if bucket < 0 || bucket > 99 {
			t.Errorf("bucket fora do intervalo [0,99]: %d para input '%s'", bucket, input)
		}
	}
}

func TestGetDeterministicBucket_DifferentInputsDifferentBuckets(t *testing.T) {
	b1 := getDeterministicBucket("user1flag-a")
	b2 := getDeterministicBucket("user2flag-a")
	b3 := getDeterministicBucket("user1flag-b")

	if b1 == b2 && b2 == b3 {
		t.Log("Aviso: todos os 3 buckets são iguais (improvável mas possível)")
	}
}

func TestGetDeterministicBucket_EmptyString(t *testing.T) {
	bucket := getDeterministicBucket("")
	if bucket < 0 || bucket > 99 {
		t.Errorf("bucket fora do intervalo para string vazia: %d", bucket)
	}
}

func newTestApp() *App {
	return &App{
		FlagServiceURL:      "http://flag-service",
		TargetingServiceURL: "http://targeting-service",
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}
}

func TestRunEvaluationLogic_FlagNil(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{Flag: nil, Rule: nil}

	result := app.runEvaluationLogic(info, "user1")
	if result != false {
		t.Error("esperado false quando Flag é nil")
	}
}

func TestRunEvaluationLogic_FlagDisabled(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: false},
		Rule: nil,
	}

	result := app.runEvaluationLogic(info, "user1")
	if result != false {
		t.Error("esperado false quando Flag está desabilitada")
	}
}

func TestRunEvaluationLogic_FlagEnabled_NoRule(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: true},
		Rule: nil,
	}

	result := app.runEvaluationLogic(info, "user1")
	if result != true {
		t.Error("esperado true quando Flag está habilitada sem regra")
	}
}

func TestRunEvaluationLogic_FlagEnabled_RuleDisabled(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: false,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(50)},
		},
	}

	result := app.runEvaluationLogic(info, "user1")
	if result != true {
		t.Error("esperado true quando Flag habilitada e regra desabilitada")
	}
}

func TestRunEvaluationLogic_Percentage100(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "full-rollout", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(100)},
		},
	}

	for i := 0; i < 50; i++ {
		userID := fmt.Sprintf("user-%d", i)
		result := app.runEvaluationLogic(info, userID)
		if result != true {
			t.Errorf("esperado true para 100%% rollout, user: %s", userID)
		}
	}
}

func TestRunEvaluationLogic_Percentage0(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "zero-rollout", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(0)},
		},
	}

	for i := 0; i < 50; i++ {
		userID := fmt.Sprintf("user-%d", i)
		result := app.runEvaluationLogic(info, userID)
		if result != false {
			t.Errorf("esperado false para 0%% rollout, user: %s", userID)
		}
	}
}

func TestRunEvaluationLogic_Percentage50_Distribution(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "half-rollout", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(50)},
		},
	}

	trueCount := 0
	total := 1000
	for i := 0; i < total; i++ {
		userID := fmt.Sprintf("user-%d", i)
		if app.runEvaluationLogic(info, userID) {
			trueCount++
		}
	}

	percentage := float64(trueCount) / float64(total) * 100
	if percentage < 35 || percentage > 65 {
		t.Errorf("distribuição de 50%% fora do esperado: %.1f%% (true: %d/%d)", percentage, trueCount, total)
	}
}

func TestRunEvaluationLogic_PercentageInvalidValue(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "bad-rule", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: "not-a-number"},
		},
	}

	result := app.runEvaluationLogic(info, "user1")
	if result != false {
		t.Error("esperado false quando o valor da porcentagem não é numérico")
	}
}

func TestRunEvaluationLogic_UnknownRuleType(t *testing.T) {
	app := newTestApp()
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "unknown", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "UNKNOWN_TYPE", Value: float64(50)},
		},
	}

	result := app.runEvaluationLogic(info, "user1")
	if result != false {
		t.Error("esperado false para tipo de regra desconhecido")
	}
}

func TestFetchFlag_Success(t *testing.T) {
	flag := Flag{ID: 1, Name: "my-flag", Description: "test", IsEnabled: true}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/flags/my-flag" {
			t.Errorf("path esperado /flags/my-flag, obteve %s", r.URL.Path)
		}
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(flag)
	}))
	defer server.Close()

	app := &App{
		FlagServiceURL: server.URL,
		HttpClient:     server.Client(),
	}

	result, err := app.fetchFlag("my-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if result.Name != "my-flag" {
		t.Errorf("nome esperado 'my-flag', obteve '%s'", result.Name)
	}
	if !result.IsEnabled {
		t.Error("esperado IsEnabled=true")
	}
}

func TestFetchFlag_NotFound(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer server.Close()

	app := &App{
		FlagServiceURL: server.URL,
		HttpClient:     server.Client(),
	}

	_, err := app.fetchFlag("nonexistent")
	if err == nil {
		t.Fatal("esperado erro para flag não encontrada")
	}
	if _, ok := err.(*NotFoundError); !ok {
		t.Errorf("esperado NotFoundError, obteve %T: %v", err, err)
	}
}

func TestFetchFlag_ServerError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer server.Close()

	app := &App{
		FlagServiceURL: server.URL,
		HttpClient:     server.Client(),
	}

	_, err := app.fetchFlag("my-flag")
	if err == nil {
		t.Fatal("esperado erro para status 500")
	}
}

func TestFetchFlag_InvalidJSON(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("not json"))
	}))
	defer server.Close()

	app := &App{
		FlagServiceURL: server.URL,
		HttpClient:     server.Client(),
	}

	_, err := app.fetchFlag("my-flag")
	if err == nil {
		t.Fatal("esperado erro para JSON inválido")
	}
}

func TestFetchFlag_ConnectionError(t *testing.T) {
	app := &App{
		FlagServiceURL: "http://localhost:1", // porta inválida
		HttpClient:     &http.Client{Timeout: 1 * time.Second},
	}

	_, err := app.fetchFlag("my-flag")
	if err == nil {
		t.Fatal("esperado erro de conexão")
	}
}

func TestFetchFlag_AuthorizationHeader(t *testing.T) {
	t.Setenv("SERVICE_API_KEY", "test-api-key")

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader != "Bearer test-api-key" {
			t.Errorf("Authorization header esperado 'Bearer test-api-key', obteve '%s'", authHeader)
		}
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(Flag{Name: "test"})
	}))
	defer server.Close()

	app := &App{
		FlagServiceURL: server.URL,
		HttpClient:     server.Client(),
	}

	_, err := app.fetchFlag("test")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
}

func TestFetchRule_Success(t *testing.T) {
	rule := TargetingRule{
		ID:        1,
		FlagName:  "my-flag",
		IsEnabled: true,
		Rules:     Rule{Type: "PERCENTAGE", Value: float64(50)},
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/rules/my-flag" {
			t.Errorf("path esperado /rules/my-flag, obteve %s", r.URL.Path)
		}
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(rule)
	}))
	defer server.Close()

	app := &App{
		TargetingServiceURL: server.URL,
		HttpClient:          server.Client(),
	}

	result, err := app.fetchRule("my-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if result.FlagName != "my-flag" {
		t.Errorf("flag_name esperado 'my-flag', obteve '%s'", result.FlagName)
	}
	if result.Rules.Type != "PERCENTAGE" {
		t.Errorf("tipo de regra esperado 'PERCENTAGE', obteve '%s'", result.Rules.Type)
	}
}

func TestFetchRule_NotFound(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer server.Close()

	app := &App{
		TargetingServiceURL: server.URL,
		HttpClient:          server.Client(),
	}

	_, err := app.fetchRule("nonexistent")
	if err == nil {
		t.Fatal("esperado erro para regra não encontrada")
	}
	if _, ok := err.(*NotFoundError); !ok {
		t.Errorf("esperado NotFoundError, obteve %T: %v", err, err)
	}
}

func TestFetchRule_ServerError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer server.Close()

	app := &App{
		TargetingServiceURL: server.URL,
		HttpClient:          server.Client(),
	}

	_, err := app.fetchRule("my-flag")
	if err == nil {
		t.Fatal("esperado erro para status 500")
	}
}

func TestFetchRule_InvalidJSON(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("not json"))
	}))
	defer server.Close()

	app := &App{
		TargetingServiceURL: server.URL,
		HttpClient:          server.Client(),
	}

	_, err := app.fetchRule("my-flag")
	if err == nil {
		t.Fatal("esperado erro para JSON inválido")
	}
}

func TestFetchRule_ConnectionError(t *testing.T) {
	app := &App{
		TargetingServiceURL: "http://localhost:1",
		HttpClient:          &http.Client{Timeout: 1 * time.Second},
	}

	_, err := app.fetchRule("my-flag")
	if err == nil {
		t.Fatal("esperado erro de conexão")
	}
}

func TestFetchFromServices_BothSuccess(t *testing.T) {
	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Flag{Name: "my-flag", IsEnabled: true})
	}))
	defer flagServer.Close()

	ruleServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(TargetingRule{
			FlagName:  "my-flag",
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(50)},
		})
	}))
	defer ruleServer.Close()

	app := &App{
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: ruleServer.URL,
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}

	info, err := app.fetchFromServices("my-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if info.Flag == nil {
		t.Fatal("Flag não deveria ser nil")
	}
	if info.Rule == nil {
		t.Fatal("Rule não deveria ser nil")
	}
}

func TestFetchFromServices_FlagError_ReturnsError(t *testing.T) {
	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer flagServer.Close()

	ruleServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(TargetingRule{FlagName: "my-flag"})
	}))
	defer ruleServer.Close()

	app := &App{
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: ruleServer.URL,
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}

	_, err := app.fetchFromServices("my-flag")
	if err == nil {
		t.Fatal("esperado erro quando flag-service falha")
	}
}

func TestFetchFromServices_RuleNotFound_ReturnsNilRule(t *testing.T) {
	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Flag{Name: "my-flag", IsEnabled: true})
	}))
	defer flagServer.Close()

	ruleServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer ruleServer.Close()

	app := &App{
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: ruleServer.URL,
		HttpClient:          &http.Client{Timeout: 5 * time.Second},
	}

	info, err := app.fetchFromServices("my-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if info.Flag == nil {
		t.Fatal("Flag não deveria ser nil")
	}
	if info.Rule != nil {
		t.Error("Rule deveria ser nil quando targeting-service retorna 404")
	}
}

func TestGetCombinedFlagInfo_CacheHit(t *testing.T) {
	db, mock := redismock.NewClientMock()
	app := &App{RedisClient: db}

	info := CombinedFlagInfo{
		Flag: &Flag{Name: "cached-flag", IsEnabled: true},
		Rule: nil,
	}
	jsonData, _ := json.Marshal(info)

	mock.ExpectGet("flag_info:cached-flag").SetVal(string(jsonData))

	result, err := app.getCombinedFlagInfo("cached-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if result.Flag.Name != "cached-flag" {
		t.Errorf("nome esperado 'cached-flag', obteve '%s'", result.Flag.Name)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestGetCombinedFlagInfo_CacheMiss_FetchesFromServices(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Flag{Name: "new-flag", IsEnabled: true})
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
		Flag: &Flag{Name: "new-flag", IsEnabled: true},
		Rule: nil,
	}
	expectedJSON, _ := json.Marshal(expectedInfo)

	redisMock.ExpectGet("flag_info:new-flag").RedisNil()
	redisMock.ExpectSet("flag_info:new-flag", expectedJSON, CACHE_TTL).SetVal("OK")

	result, err := app.getCombinedFlagInfo("new-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if result.Flag.Name != "new-flag" {
		t.Errorf("nome esperado 'new-flag', obteve '%s'", result.Flag.Name)
	}

	if err := redisMock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestGetCombinedFlagInfo_CacheInvalidJSON_FetchesFromServices(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Flag{Name: "bad-cache", IsEnabled: true})
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
		Flag: &Flag{Name: "bad-cache", IsEnabled: true},
		Rule: nil,
	}
	expectedJSON, _ := json.Marshal(expectedInfo)

	redisMock.ExpectGet("flag_info:bad-cache").SetVal("invalid-json{{{")
	redisMock.ExpectSet("flag_info:bad-cache", expectedJSON, CACHE_TTL).SetVal("OK")

	result, err := app.getCombinedFlagInfo("bad-cache")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if result.Flag.Name != "bad-cache" {
		t.Errorf("nome esperado 'bad-cache', obteve '%s'", result.Flag.Name)
	}
}

func TestGetDecision_FlagEnabled_NoRule_ReturnsTrue(t *testing.T) {
	db, redisMock := redismock.NewClientMock()

	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Flag{Name: "simple-flag", IsEnabled: true})
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
		Flag: &Flag{Name: "simple-flag", IsEnabled: true},
		Rule: nil,
	}
	expectedJSON, _ := json.Marshal(expectedInfo)

	redisMock.ExpectGet("flag_info:simple-flag").RedisNil()
	redisMock.ExpectSet("flag_info:simple-flag", expectedJSON, CACHE_TTL).SetVal("OK")

	result, err := app.getDecision("user1", "simple-flag")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if result != true {
		t.Error("esperado true para flag habilitada sem regra")
	}
}

func TestGetDecision_FlagNotFound_ReturnsError(t *testing.T) {
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

	_, err := app.getDecision("user1", "nonexistent")
	if err == nil {
		t.Fatal("esperado erro quando flag não encontrada")
	}
}
