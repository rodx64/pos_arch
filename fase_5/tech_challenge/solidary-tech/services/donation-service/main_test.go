package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestHealthHandler(t *testing.T) {
	app := &App{}
	req := httptest.NewRequest(http.MethodGet, "/donations/health", nil)
	rr := httptest.NewRecorder()

	app.HealthHandler(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rr.Code)
	}

	var data map[string]string
	if err := json.NewDecoder(rr.Body).Decode(&data); err != nil {
		t.Fatal(err)
	}

	if data["status"] != "ok" || data["service"] != "donation-service" {
		t.Fatalf("unexpected body: %v", data)
	}
}

func TestDonationHandlerInvalidJSON(t *testing.T) {
	app := &App{}
	req := httptest.NewRequest(http.MethodPost, "/donations", strings.NewReader(`{invalid`))
	rr := httptest.NewRecorder()

	app.DonationHandler(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rr.Code)
	}
}

func TestDonationHandlerPostSuccess(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	app := &App{DB: db}
	body := strings.NewReader(`{"ngo_id":1,"amount":100.5,"donor_name":"John Doe"}`)
	req := httptest.NewRequest(http.MethodPost, "/donations", body)
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()

	mock.ExpectQuery("INSERT INTO donations.*RETURNING id, created_at").
		WithArgs(1, 100.5, "John Doe", "APPROVED").
		WillReturnRows(sqlmock.NewRows([]string{"id", "created_at"}).AddRow(1, time.Now()))

	app.DonationHandler(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("expected status 201, got %d", rr.Code)
	}

	var d Donation
	if err := json.NewDecoder(rr.Body).Decode(&d); err != nil {
		t.Fatal(err)
	}

	if d.ID != 1 || d.NgoID != 1 || d.Amount != 100.5 || d.DonorName != "John Doe" || d.Status != "APPROVED" {
		t.Fatalf("unexpected donation: %#v", d)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestDonationHandlerGetSuccess(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	app := &App{DB: db}
	req := httptest.NewRequest(http.MethodGet, "/donations", nil)
	rr := httptest.NewRecorder()

	rows := sqlmock.NewRows([]string{"id", "ngo_id", "amount", "donor_name", "status", "created_at"}).
		AddRow(1, 1, 100.5, "John Doe", "APPROVED", time.Now())

	mock.ExpectQuery("SELECT id, ngo_id, amount, donor_name, status, created_at FROM donations ORDER BY id DESC").
		WillReturnRows(rows)

	app.DonationHandler(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rr.Code)
	}

	var donations []Donation
	if err := json.NewDecoder(rr.Body).Decode(&donations); err != nil {
		t.Fatal(err)
	}

	if len(donations) != 1 || donations[0].DonorName != "John Doe" {
		t.Fatalf("unexpected donations: %#v", donations)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestDonationHandlerMethodNotAllowed(t *testing.T) {
	app := &App{}
	req := httptest.NewRequest(http.MethodPut, "/donations", nil)
	rr := httptest.NewRecorder()

	app.DonationHandler(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected status 405, got %d", rr.Code)
	}
}
