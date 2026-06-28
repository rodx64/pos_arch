package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"math"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

type Donation struct {
	ID        int       `json:"id"`
	NgoID     int       `json:"ngo_id"`
	Amount    float64   `json:"amount"`
	DonorName string    `json:"donor_name"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

type App struct {
	DB          *sql.DB
	SqsSvc      *sqs.SQS
	SqsQueueURL string
	Metrics     *AppMetrics
}

type AppMetrics struct {
	httpRequestsTotal     *prometheus.CounterVec
	httpRequestDuration   *prometheus.HistogramVec
	dbUp                  prometheus.Gauge
	donationsCreatedTotal prometheus.Counter
}

func newMetrics() *AppMetrics {
	m := &AppMetrics{
		httpRequestsTotal: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_requests_total",
				Help: "Total de requisições HTTP",
			},
			[]string{"method", "path", "status"},
		),
		httpRequestDuration: prometheus.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_request_duration_seconds",
				Help:    "Duração das requisições",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"method", "path", "status"},
		),
		dbUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "db_up",
			Help: "Status da conexão com o banco de dados (1 = UP, 0 = DOWN)",
		}),
		donationsCreatedTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "donations_created_total",
			Help: "Total de doações criadas com sucesso",
		}),
	}

	prometheus.MustRegister(
		m.httpRequestsTotal,
		m.httpRequestDuration,
		m.dbUp,
		m.donationsCreatedTotal,
	)

	return m
}

func initTracer() (func(context.Context) error, error) {
	ctx := context.Background()
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("donation-service"),
			semconv.DeploymentEnvironmentKey.String(os.Getenv("DD_ENV")),
		),
	)
	if err != nil {
		return nil, err
	}

	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "otel-collector.monitoring.svc.cluster.local:4317"
	}

	traceExporter, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithInsecure(),
		otlptracegrpc.WithEndpoint(endpoint),
	)
	if err != nil {
		return nil, err
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(traceExporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))

	return tp.Shutdown, nil
}

func (a *App) watchDB() {
	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		if err := a.DB.Ping(); err != nil {
			log.Printf("DB ping falhou: %v", err)
			a.Metrics.dbUp.Set(0)
		} else {
			a.Metrics.dbUp.Set(1)
		}
	}
}

func (a *App) instrumentHandler(path string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rw := &responseWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rw, r)
		duration := time.Since(start).Seconds()
		a.Metrics.httpRequestsTotal.WithLabelValues(r.Method, path, http.StatusText(rw.status)).Inc()
		a.Metrics.httpRequestDuration.WithLabelValues(r.Method, path, http.StatusText(rw.status)).Observe(duration)
	})
}

type responseWriter struct {
	http.ResponseWriter
	status int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.status = code
	rw.ResponseWriter.WriteHeader(code)
}

// cpuMaxDurationMs limita o tempo máximo de "queima" de CPU por requisição, evitando que o endpoint seja usado em DDOS.
const cpuMaxDurationMs = 500
const cpuDefaultDurationMs = 50

// burnCPU executa um laço de cálculo (sem alocação relevante, sem I/O) com durationMs milissegundos, para gerar carga de
// CPU real e previsível — usado por testes de carga (k6) e calibração de HPA/KEDA.
func burnCPU(durationMs int) float64 {
	deadline := time.Now().Add(time.Duration(durationMs) * time.Millisecond)
	result := 0.0
	i := 0
	for time.Now().Before(deadline) {
		for j := 0; j < 5000; j++ {
			i++
			result += math.Sqrt(float64(i)) * math.Sin(float64(i))
		}
	}
	return result
}

func main() {
	_ = godotenv.Load()

	shutdown, err := initTracer()
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err := shutdown(context.Background()); err != nil {
			log.Printf("Erro ao fechar o tracer: %v", err)
		}
	}()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL é obrigatória")
	}

	db, err := sql.Open("pgx", dbURL)
	if err != nil {
		log.Fatalf("Erro ao conectar ao banco de dados: %v", err)
	}
	defer db.Close()

	var sqsSvc *sqs.SQS
	queueURL := os.Getenv("AWS_SQS_URL")
	region := os.Getenv("AWS_REGION")
	endpoint := os.Getenv("AWS_ENDPOINT_URL")
	if queueURL != "" && region != "" {
		config := aws.NewConfig().WithRegion(region)
		if endpoint != "" {
			config = config.WithEndpoint(endpoint)
		}
		sess, err := session.NewSession(config)
		if err != nil {
			log.Fatalf("Erro ao criar sessão AWS: %v", err)
		}
		sqsSvc = sqs.New(sess)
		log.Println("Integração com AWS SQS ativada.")
	}

	app := &App{
		DB:          db,
		SqsSvc:      sqsSvc,
		SqsQueueURL: queueURL,
		Metrics:     newMetrics(),
	}

	app.Metrics.dbUp.Set(1)
	go app.watchDB()

	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())
	mux.Handle("/donations/health", otelhttp.NewHandler(app.instrumentHandler("/donations/health", http.HandlerFunc(app.HealthHandler)), "HealthCheck"))
	mux.Handle("/donations", otelhttp.NewHandler(app.instrumentHandler("/donations", http.HandlerFunc(app.DonationHandler)), "Donations"))
	mux.Handle("/cpu", otelhttp.NewHandler(app.instrumentHandler("/cpu", http.HandlerFunc(app.CPUHandler)), "CPUStress"))

	host := os.Getenv("HOST")
	if host == "" {
		host = "0.0.0.0"
	}
	addr := host + ":" + port

	server := &http.Server{
		Addr:         addr,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	cleanPort := strings.ReplaceAll(strings.ReplaceAll(port, "\n", ""), "\r", "")
	log.Printf("donation-service (OTel + Prom) rodando na porta %s", cleanPort)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

func (a *App) HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if _, err := w.Write([]byte(`{"status":"ok","service":"donation-service"}`)); err != nil {
		log.Printf("Erro ao escrever health response: %v", err)
	}
}

// CPUHandler é um endpoint sintético de estresse de CPU, usado pelo k6 (k6-load-test.yaml) para calibrar HPA/KEDA.
// Aceita um parâmetro opcional "duration_ms" (em milissegundos) para controlar a duração do estresse de CPU.
// Não tem efeito sobre o banco de dados nem sobre a fila — é puramente computacional.
func (a *App) CPUHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	durationMs := cpuDefaultDurationMs
	if raw := r.URL.Query().Get("duration_ms"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			durationMs = parsed
		}
	}
	if durationMs > cpuMaxDurationMs {
		durationMs = cpuMaxDurationMs
	}

	result := burnCPU(durationMs)

	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "ok",
		"service":     "donation-service",
		"duration_ms": durationMs,
		"result":      result,
	}); err != nil {
		log.Printf("Erro ao codificar resposta de /cpu: %v", err)
	}
}

func (a *App) DonationHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodPost {
		var d Donation
		if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
			http.Error(w, `{"error":"Payload inválido"}`, http.StatusBadRequest)
			return
		}

		d.Status = "APPROVED"
		err := a.DB.QueryRowContext(r.Context(),
			"INSERT INTO donations (ngo_id, amount, donor_name, status) VALUES ($1, $2, $3, $4) RETURNING id, created_at",
			d.NgoID, d.Amount, d.DonorName, d.Status,
		).Scan(&d.ID, &d.CreatedAt)

		if err != nil {
			log.Printf("Erro ao salvar doação: %v", err)
			http.Error(w, `{"error":"Erro interno"}`, http.StatusInternalServerError)
			return
		}

		a.Metrics.donationsCreatedTotal.Inc()

		if a.SqsSvc != nil {
			go a.sendNotificationEvent(d)
		}

		w.WriteHeader(http.StatusCreated)
		if err := json.NewEncoder(w).Encode(d); err != nil {
			log.Printf("Erro ao codificar resposta de doação: %v", err)
		}
		return
	}

	if r.Method == http.MethodGet {
		rows, err := a.DB.QueryContext(r.Context(), "SELECT id, ngo_id, amount, donor_name, status, created_at FROM donations ORDER BY id DESC")
		if err != nil {
			http.Error(w, `{"error":"Erro interno"}`, http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		donations := []Donation{}
		for rows.Next() {
			var d Donation
			if err := rows.Scan(&d.ID, &d.NgoID, &d.Amount, &d.DonorName, &d.Status, &d.CreatedAt); err != nil {
				log.Printf("Erro ao ler linha de doação: %v", err)
				http.Error(w, `{"error":"Erro interno"}`, http.StatusInternalServerError)
				return
			}
			donations = append(donations, d)
		}

		if err := json.NewEncoder(w).Encode(donations); err != nil {
			log.Printf("Erro ao codificar lista de doações: %v", err)
		}
		return
	}

	http.Error(w, `{"error":"Método não permitido"}`, http.StatusMethodNotAllowed)
}

func (a *App) sendNotificationEvent(d Donation) {
	body, _ := json.Marshal(d)
	_, err := a.SqsSvc.SendMessage(&sqs.SendMessageInput{
		MessageBody: aws.String(string(body)),
		QueueUrl:    aws.String(a.SqsQueueURL),
	})
	if err != nil {
		log.Printf("Falha ao despachar evento SQS: %v", err)
	}
}
