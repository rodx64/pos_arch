package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	// OTel Imports
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

type App struct {
	DB        *sql.DB
	MasterKey string
	Metrics   *AppMetrics
}

type AppMetrics struct {
	httpRequestsTotal   *prometheus.CounterVec
	httpRequestDuration *prometheus.HistogramVec
	dbUp                prometheus.Gauge
	keysCreatedTotal    prometheus.Counter
	keysValidatedTotal  *prometheus.CounterVec
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
			[]string{"method", "path"},
		),
		dbUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "db_up",
		}),
		keysCreatedTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "auth_keys_created_total",
		}),
		keysValidatedTotal: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Name: "auth_keys_validated_total",
			},
			[]string{"result"},
		),
	}

	prometheus.MustRegister(
		m.httpRequestsTotal,
		m.httpRequestDuration,
		m.dbUp,
		m.keysCreatedTotal,
		m.keysValidatedTotal,
	)

	return m
}

func initTracer() (func(context.Context) error, error) {
	ctx := context.Background()
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("auth-service"),
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
		a.Metrics.httpRequestDuration.WithLabelValues(r.Method, path).Observe(duration)
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
		port = "8001"
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL não definida")
	}

	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	app := &App{
		DB:        db,
		MasterKey: os.Getenv("MASTER_KEY"),
		Metrics:   newMetrics(),
	}

	app.Metrics.dbUp.Set(1)
	go app.watchDB()

	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())

	mux.Handle("/health", otelhttp.NewHandler(app.instrumentHandler("/health", http.HandlerFunc(app.healthHandler)), "HealthCheck"))
	mux.Handle("/validate", otelhttp.NewHandler(app.instrumentHandler("/validate", http.HandlerFunc(app.validateKeyHandler)), "ValidateKey"))
	mux.Handle("/admin/keys", otelhttp.NewHandler(app.masterKeyAuthMiddleware(app.instrumentHandler("/admin/keys", http.HandlerFunc(app.createKeyHandler))), "CreateKey"))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  15 * time.Second,
	}

	cleanPort := strings.ReplaceAll(strings.ReplaceAll(port, "\n", ""), "\r", "")

	log.Printf("Serviço Auth (OTel) rodando na porta %s", cleanPort)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
