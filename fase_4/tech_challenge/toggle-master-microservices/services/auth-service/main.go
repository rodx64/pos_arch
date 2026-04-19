package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v4/stdlib"
	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	sqltrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/database/sql"
	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

// App struct (para injeção de dependência)
type App struct {
	DB        *sql.DB
	MasterKey string
	Metrics   *AppMetrics
}

// AppMetrics agrupa todas as métricas Prometheus da aplicação
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
				Help: "Total de requisições HTTP por método, rota e status",
			},
			[]string{"method", "path", "status"},
		),
		httpRequestDuration: prometheus.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_request_duration_seconds",
				Help:    "Duração das requisições HTTP em segundos",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"method", "path"},
		),
		dbUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "db_up",
			Help: "1 se o banco de dados está acessível, 0 se não",
		}),
		keysCreatedTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "auth_keys_created_total",
			Help: "Total de chaves de API criadas",
		}),
		keysValidatedTotal: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Name: "auth_keys_validated_total",
				Help: "Total de validações de chave por resultado",
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

func main() {
	_ = godotenv.Load()

	// --- Inicializa o Datadog APM Tracer ---
	tracer.Start(
		tracer.WithServiceName("auth-service"),
		tracer.WithEnv(os.Getenv("DD_ENV")),
		tracer.WithServiceVersion(os.Getenv("DD_VERSION")),
	)
	defer tracer.Stop()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL deve ser definida")
	}

	masterKey := os.Getenv("MASTER_KEY")
	if masterKey == "" {
		log.Fatal("MASTER_KEY deve ser definida")
	}

	db, err := connectDB(databaseURL)
	if err != nil {
		log.Fatalf("Não foi possível conectar ao banco de dados: %v", err)
	}
	defer db.Close()

	app := &App{
		DB:        db,
		MasterKey: masterKey,
		Metrics:   newMetrics(),
	}

	app.Metrics.dbUp.Set(1)

	go app.watchDB()

	// Mux instrumentado com APM — rastreia todas as rotas HTTP
	mux := httptrace.NewServeMux(httptrace.WithServiceName("auth-service"))

	mux.Handle("/metrics", promhttp.Handler())
	mux.Handle("/health", app.instrumentHandler("/health", http.HandlerFunc(app.healthHandler)))
	mux.Handle("/validate", app.instrumentHandler("/validate", http.HandlerFunc(app.validateKeyHandler)))
	mux.Handle("/admin/keys", app.instrumentHandler("/admin/keys",
		app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler)),
	))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  15 * time.Second,
	}

	// #nosec G706
	log.Printf("Serviço de Autenticação (Go) rodando na porta %q", port)
	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}

// connectDB inicializa e testa a conexão com o PostgreSQL instrumentada com APM
func connectDB(databaseURL string) (*sql.DB, error) {
	// Registra o driver pgx instrumentado — cada query vira um span no APM
	sqltrace.Register("pgx", &stdlib.Driver{}, sqltrace.WithServiceName("auth-service-db"))
	db, err := sqltrace.Open("pgx", databaseURL)
	if err != nil {
		return nil, err
	}
	if err = db.Ping(); err != nil {
		return nil, err
	}
	log.Println("Conectado ao PostgreSQL com sucesso!")
	return db, nil
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
		status := http.StatusText(rw.status)

		a.Metrics.httpRequestsTotal.WithLabelValues(r.Method, path, status).Inc()
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
