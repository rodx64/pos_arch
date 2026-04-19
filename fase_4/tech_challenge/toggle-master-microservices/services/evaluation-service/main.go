package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/go-redis/redis/v8"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

var ctx = context.Background()

type App struct {
	RedisClient         *redis.Client
	SqsSvc              *sqs.SQS
	SqsQueueURL         string
	HttpClient          *http.Client
	FlagServiceURL      string
	TargetingServiceURL string
	Metrics             *AppMetrics
}

type AppMetrics struct {
	httpRequestsTotal      *prometheus.CounterVec
	httpRequestDuration    *prometheus.HistogramVec
	evaluationsTotal       *prometheus.CounterVec
	cacheHitsTotal         prometheus.Counter
	cacheMissesTotal       prometheus.Counter
	sqsEventsSentTotal     prometheus.Counter
	sqsEventsFailedTotal   prometheus.Counter
	flagServiceErrorsTotal prometheus.Counter
	redisUp                prometheus.Gauge
	sqsUp                  prometheus.Gauge
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
		evaluationsTotal: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Name: "evaluations_total",
				Help: "Total de avaliações de flag por resultado",
			},
			[]string{"flag_name", "result"},
		),
		cacheHitsTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "cache_hits_total",
			Help: "Total de cache hits no Redis",
		}),
		cacheMissesTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "cache_misses_total",
			Help: "Total de cache misses no Redis",
		}),
		sqsEventsSentTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "sqs_events_sent_total",
			Help: "Total de eventos enviados ao SQS com sucesso",
		}),
		sqsEventsFailedTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "sqs_events_failed_total",
			Help: "Total de eventos que falharam ao enviar para o SQS",
		}),
		flagServiceErrorsTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "flag_service_errors_total",
			Help: "Total de erros ao chamar flag-service ou targeting-service",
		}),
		redisUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "redis_up",
			Help: "1 se o Redis está acessível, 0 se não",
		}),
		sqsUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "sqs_up",
			Help: "1 se o SQS está acessível, 0 se não",
		}),
	}

	for _, c := range []prometheus.Collector{
		m.httpRequestsTotal,
		m.httpRequestDuration,
		m.evaluationsTotal,
		m.cacheHitsTotal,
		m.cacheMissesTotal,
		m.sqsEventsSentTotal,
		m.sqsEventsFailedTotal,
		m.flagServiceErrorsTotal,
		m.redisUp,
		m.sqsUp,
	} {
		_ = prometheus.Register(c)
	}

	return m
}

func main() {
	_ = godotenv.Load()

	tracer.Start(
		tracer.WithServiceName("evaluation-service"),
		tracer.WithEnv(os.Getenv("DD_ENV")),
		tracer.WithServiceVersion(os.Getenv("DD_VERSION")),
	)
	defer tracer.Stop()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8004"
	}

	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		log.Fatal("REDIS_URL deve ser definida (ex: redis://localhost:6379)")
	}

	flagSvcURL := os.Getenv("FLAG_SERVICE_URL")
	if flagSvcURL == "" {
		log.Fatal("FLAG_SERVICE_URL deve ser definida")
	}

	targetingSvcURL := os.Getenv("TARGETING_SERVICE_URL")
	if targetingSvcURL == "" {
		log.Fatal("TARGETING_SERVICE_URL deve ser definida")
	}

	sqsQueueURL := os.Getenv("AWS_SQS_URL")
	awsRegion := os.Getenv("AWS_REGION")
	if sqsQueueURL == "" {
		log.Println("Atenção: AWS_SQS_URL não definida. Eventos não serão enviados.")
	}
	if awsRegion == "" && sqsQueueURL != "" {
		log.Fatal("AWS_REGION deve ser definida para usar SQS")
	}

	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		log.Fatalf("Não foi possível parsear a URL do Redis: %v", err)
	}
	rdb := redis.NewClient(opt)
	if _, err := rdb.Ping(ctx).Result(); err != nil {
		log.Fatalf("Não foi possível conectar ao Redis: %v", err)
	}
	log.Println("Conectado ao Redis com sucesso!")

	var sqsSvc *sqs.SQS
	if sqsQueueURL != "" {
		sess, err := session.NewSession(&aws.Config{Region: aws.String(awsRegion)})
		if err != nil {
			log.Fatalf("Não foi possível criar sessão AWS: %v", err)
		}
		sqsSvc = sqs.New(sess)
		log.Println("Cliente SQS inicializado com sucesso.")
	}

	// HttpClient instrumentado com APM — rastreia chamadas para flag/targeting service
	httpClient := &http.Client{
		Timeout:   5 * time.Second,
		Transport: httptrace.WrapRoundTripper(http.DefaultTransport),
	}

	app := &App{
		RedisClient:         rdb,
		SqsSvc:              sqsSvc,
		SqsQueueURL:         sqsQueueURL,
		HttpClient:          httpClient,
		FlagServiceURL:      flagSvcURL,
		TargetingServiceURL: targetingSvcURL,
		Metrics:             newMetrics(),
	}

	app.Metrics.redisUp.Set(1)
	if sqsSvc != nil {
		app.Metrics.sqsUp.Set(1)
	}

	go app.watchDependencies()

	// Mux instrumentado com APM — rastreia todas as rotas HTTP
	mux := httptrace.NewServeMux(httptrace.WithServiceName("evaluation-service"))
	mux.Handle("/metrics", promhttp.Handler())
	mux.Handle("/health", app.instrumentHandler("/health", http.HandlerFunc(app.healthHandler)))
	mux.Handle("/evaluate", app.instrumentHandler("/evaluate", http.HandlerFunc(app.evaluationHandler)))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  15 * time.Second,
	}

	log.Printf("Serviço de Avaliação (Go) rodando na porta %q", port) // #nosec G706
	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}

func (a *App) watchDependencies() {
	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		if err := a.RedisClient.Ping(ctx).Err(); err != nil {
			log.Printf("Redis ping falhou: %v", err)
			a.Metrics.redisUp.Set(0)
		} else {
			a.Metrics.redisUp.Set(1)
		}

		if a.SqsSvc != nil {
			_, err := a.SqsSvc.GetQueueAttributes(&sqs.GetQueueAttributesInput{
				QueueUrl:       aws.String(a.SqsQueueURL),
				AttributeNames: []*string{aws.String("ApproximateNumberOfMessages")},
			})
			if err != nil {
				log.Printf("SQS health check falhou: %v", err)
				a.Metrics.sqsUp.Set(0)
			} else {
				a.Metrics.sqsUp.Set(1)
			}
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
