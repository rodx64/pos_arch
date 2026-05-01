package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/go-redis/redis/v8"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

var ctxGlobal = context.Background()

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
		evaluationsTotal: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Name: "evaluations_total",
				Help: "Total de avaliações de flags",
			},
			[]string{"flag_name", "result"},
		),
		cacheHitsTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "cache_hits_total",
			Help: "Total de sucessos no cache Redis",
		}),
		cacheMissesTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "cache_misses_total",
			Help: "Total de falhas no cache Redis",
		}),
		sqsEventsSentTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "sqs_events_sent_total",
			Help: "Eventos enviados ao SQS",
		}),
		sqsEventsFailedTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "sqs_events_failed_total",
			Help: "Falhas no envio ao SQS",
		}),
		flagServiceErrorsTotal: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "flag_service_errors_total",
			Help: "Erros em serviços upstream",
		}),
		redisUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "redis_up",
			Help: "Status da conexão com Redis",
		}),
		sqsUp: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "sqs_up",
			Help: "Status da conexão com SQS",
		}),
	}

	collectors := []prometheus.Collector{
		m.httpRequestsTotal, m.httpRequestDuration, m.evaluationsTotal,
		m.cacheHitsTotal, m.cacheMissesTotal, m.sqsEventsSentTotal,
		m.sqsEventsFailedTotal, m.flagServiceErrorsTotal, m.redisUp, m.sqsUp,
	}

	for _, c := range collectors {
		_ = prometheus.Register(c)
	}

	return m
}

func (a *App) watchDependencies() {
	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		if err := a.RedisClient.Ping(ctxGlobal).Err(); err != nil {
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

func initTracer() (func(context.Context) error, error) {
	ctx := context.Background()
	res, err := resource.New(ctx,
		resource.WithFromEnv(),
		resource.WithTelemetrySDK(),
	)
	if err != nil {
		return nil, err
	}

	traceExporter, err := otlptracegrpc.New(ctx)
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

func main() {
	_ = godotenv.Load()
	shutdown, err := initTracer()
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err := shutdown(context.Background()); err != nil {
			log.Printf("Erro ao fechar tracer: %v", err)
		}
	}()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8004"
	}

	opt, _ := redis.ParseURL(os.Getenv("REDIS_URL"))
	rdb := redis.NewClient(opt)

	sess, _ := session.NewSession(&aws.Config{Region: aws.String(os.Getenv("AWS_REGION"))})
	sqsSvc := sqs.New(sess)

	app := &App{
		RedisClient:         rdb,
		SqsSvc:              sqsSvc,
		SqsQueueURL:         os.Getenv("AWS_SQS_URL"),
		HttpClient:          &http.Client{Timeout: 5 * time.Second, Transport: otelhttp.NewTransport(http.DefaultTransport)},
		FlagServiceURL:      os.Getenv("FLAG_SERVICE_URL"),
		TargetingServiceURL: os.Getenv("TARGETING_SERVICE_URL"),
		Metrics:             newMetrics(),
	}

	go app.watchDependencies()

	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())
	mux.Handle("/health", otelhttp.NewHandler(app.instrumentHandler("/health", http.HandlerFunc(app.healthHandler)), "HealthCheck"))
	mux.Handle("/evaluate", otelhttp.NewHandler(app.instrumentHandler("/evaluate", http.HandlerFunc(app.evaluationHandler)), "EvaluateFlag"))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  15 * time.Second,
	}

	cleanPort := strings.ReplaceAll(strings.ReplaceAll(port, "\n", ""), "\r", "")
	log.Printf("Evaluation Service (OTel) na porta %s", cleanPort)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
