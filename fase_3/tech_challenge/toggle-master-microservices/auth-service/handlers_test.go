package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
)

func newTestApp(t *testing.T) (*App, sqlmock.Sqlmock) {
	t.Helper()
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("erro ao criar sqlmock: %v", err)
	}
	app := &App{
		DB:        db,
		MasterKey: "test-master-key",
	}
	return app, mock
}

func TestHealthHandler_ReturnsOK(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

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
}

func TestValidateKeyHandler_MissingAuthHeader(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("status esperado %d, obteve %d", http.StatusUnauthorized, w.Code)
	}
}

func TestValidateKeyHandler_EmptyBearerToken(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	req.Header.Set("Authorization", "Bearer ")
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("status esperado %d, obteve %d", http.StatusUnauthorized, w.Code)
	}
}

func TestValidateKeyHandler_ValidKey(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	apiKey := "tm_key_valid123"
	keyHash := hashAPIKey(apiKey)

	rows := sqlmock.NewRows([]string{"id"}).AddRow(1)
	mock.ExpectQuery("SELECT id FROM api_keys WHERE key_hash = \\$1 AND is_active = true").
		WithArgs(keyHash).
		WillReturnRows(rows)

	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	req.Header.Set("Authorization", "Bearer "+apiKey)
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}

	var resp map[string]string
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}
	if resp["message"] != "Chave válida" {
		t.Errorf("mensagem esperada 'Chave válida', obteve '%s'", resp["message"])
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestValidateKeyHandler_InvalidKey(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	apiKey := "tm_key_invalid"
	keyHash := hashAPIKey(apiKey)

	mock.ExpectQuery("SELECT id FROM api_keys WHERE key_hash = \\$1 AND is_active = true").
		WithArgs(keyHash).
		WillReturnError(sqlmock.ErrCancelled)

	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	req.Header.Set("Authorization", "Bearer "+apiKey)
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("status esperado %d, obteve %d", http.StatusUnauthorized, w.Code)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestValidateKeyHandler_AuthHeaderWithoutBearer(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	apiKey := "some-raw-key"
	keyHash := hashAPIKey(apiKey)

	mock.ExpectQuery("SELECT id FROM api_keys WHERE key_hash = \\$1 AND is_active = true").
		WithArgs(keyHash).
		WillReturnError(sqlmock.ErrCancelled)

	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	req.Header.Set("Authorization", apiKey)
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("status esperado %d, obteve %d", http.StatusUnauthorized, w.Code)
	}
}

func TestCreateKeyHandler_MethodNotAllowed(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	methods := []string{http.MethodGet, http.MethodPut, http.MethodDelete, http.MethodPatch}
	for _, method := range methods {
		req := httptest.NewRequest(method, "/admin/keys", nil)
		w := httptest.NewRecorder()

		app.createKeyHandler(w, req)

		if w.Code != http.StatusMethodNotAllowed {
			t.Errorf("[%s] status esperado %d, obteve %d", method, http.StatusMethodNotAllowed, w.Code)
		}
	}
}

func TestCreateKeyHandler_InvalidBody(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	req := httptest.NewRequest(http.MethodPost, "/admin/keys", bytes.NewBufferString("invalid json"))
	w := httptest.NewRecorder()

	app.createKeyHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("status esperado %d, obteve %d", http.StatusBadRequest, w.Code)
	}
}

func TestCreateKeyHandler_EmptyName(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	body, _ := json.Marshal(CreateKeyRequest{Name: ""})
	req := httptest.NewRequest(http.MethodPost, "/admin/keys", bytes.NewBuffer(body))
	w := httptest.NewRecorder()

	app.createKeyHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("status esperado %d, obteve %d", http.StatusBadRequest, w.Code)
	}
}

func TestCreateKeyHandler_Success(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	rows := sqlmock.NewRows([]string{"id"}).AddRow(42)
	mock.ExpectQuery("INSERT INTO api_keys").
		WithArgs("minha-api", sqlmock.AnyArg()).
		WillReturnRows(rows)

	body, _ := json.Marshal(CreateKeyRequest{Name: "minha-api"})
	req := httptest.NewRequest(http.MethodPost, "/admin/keys", bytes.NewBuffer(body))
	w := httptest.NewRecorder()

	app.createKeyHandler(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("status esperado %d, obteve %d", http.StatusCreated, w.Code)
	}

	var resp CreateKeyResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}

	if resp.Name != "minha-api" {
		t.Errorf("nome esperado 'minha-api', obteve '%s'", resp.Name)
	}
	if resp.Key == "" {
		t.Error("chave retornada não deveria ser vazia")
	}
	if resp.Message == "" {
		t.Error("mensagem retornada não deveria ser vazia")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestCreateKeyHandler_DBError(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	mock.ExpectQuery("INSERT INTO api_keys").
		WithArgs("minha-api", sqlmock.AnyArg()).
		WillReturnError(sqlmock.ErrCancelled)

	body, _ := json.Marshal(CreateKeyRequest{Name: "minha-api"})
	req := httptest.NewRequest(http.MethodPost, "/admin/keys", bytes.NewBuffer(body))
	w := httptest.NewRecorder()

	app.createKeyHandler(w, req)

	if w.Code != http.StatusInternalServerError {
		t.Errorf("status esperado %d, obteve %d", http.StatusInternalServerError, w.Code)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestMasterKeyAuthMiddleware_ValidKey(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	called := false
	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/admin/keys", nil)
	req.Header.Set("Authorization", "Bearer test-master-key")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if !called {
		t.Error("handler interno não foi chamado com chave válida")
	}
	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}
}

func TestMasterKeyAuthMiddleware_InvalidKey(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	called := false
	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
	}))

	req := httptest.NewRequest(http.MethodGet, "/admin/keys", nil)
	req.Header.Set("Authorization", "Bearer wrong-key")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if called {
		t.Error("handler interno foi chamado com chave inválida")
	}
	if w.Code != http.StatusForbidden {
		t.Errorf("status esperado %d, obteve %d", http.StatusForbidden, w.Code)
	}
}

func TestMasterKeyAuthMiddleware_MissingHeader(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	called := false
	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
	}))

	req := httptest.NewRequest(http.MethodGet, "/admin/keys", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if called {
		t.Error("handler interno foi chamado sem header de autorização")
	}
	if w.Code != http.StatusForbidden {
		t.Errorf("status esperado %d, obteve %d", http.StatusForbidden, w.Code)
	}
}

func TestMasterKeyAuthMiddleware_EmptyBearerToken(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	called := false
	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
	}))

	req := httptest.NewRequest(http.MethodGet, "/admin/keys", nil)
	req.Header.Set("Authorization", "Bearer ")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if called {
		t.Error("handler interno foi chamado com token Bearer vazio")
	}
	if w.Code != http.StatusForbidden {
		t.Errorf("status esperado %d, obteve %d", http.StatusForbidden, w.Code)
	}
}

func TestCreateKeyFlow_WithMiddleware(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	rows := sqlmock.NewRows([]string{"id"}).AddRow(1)
	mock.ExpectQuery("INSERT INTO api_keys").
		WithArgs("integration-test", sqlmock.AnyArg()).
		WillReturnRows(rows)

	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler))

	body, _ := json.Marshal(CreateKeyRequest{Name: "integration-test"})
	req := httptest.NewRequest(http.MethodPost, "/admin/keys", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer test-master-key")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("status esperado %d, obteve %d", http.StatusCreated, w.Code)
	}

	var resp CreateKeyResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("erro ao decodificar resposta: %v", err)
	}
	if resp.Name != "integration-test" {
		t.Errorf("nome esperado 'integration-test', obteve '%s'", resp.Name)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}

func TestCreateKeyFlow_WithMiddleware_Unauthorized(t *testing.T) {
	app, _ := newTestApp(t)
	defer app.DB.Close()

	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler))

	body, _ := json.Marshal(CreateKeyRequest{Name: "test"})
	req := httptest.NewRequest(http.MethodPost, "/admin/keys", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer wrong-key")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Errorf("status esperado %d, obteve %d", http.StatusForbidden, w.Code)
	}
}

func TestValidateKeyFlow_FullCycle(t *testing.T) {
	app, mock := newTestApp(t)
	defer app.DB.Close()

	apiKey := "tm_key_fullcycle123"
	keyHash := hashAPIKey(apiKey)

	rows := sqlmock.NewRows([]string{"id"}).AddRow(1)
	mock.ExpectQuery("SELECT id FROM api_keys WHERE key_hash = \\$1 AND is_active = true").
		WithArgs(keyHash).
		WillReturnRows(rows)

	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	req.Header.Set("Authorization", "Bearer "+apiKey)
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status esperado %d, obteve %d", http.StatusOK, w.Code)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas do mock não atendidas: %v", err)
	}
}
