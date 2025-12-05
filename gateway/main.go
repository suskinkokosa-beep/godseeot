package main

// Gateway with optional Redis-backed rate limiter and Prometheus metrics
// Env vars:
//  USE_REDIS_RATE=true  -> enable redis rate limiter
//  REDIS_URL=redis://redis:6379/0
//  RATE_LIMIT_RPS=5
//  RATE_LIMIT_BURST=10
//  METRICS_PATH=/metrics (default)
//
// Prometheus metrics exposed on /metrics
//
import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-redis/redis/v8"
	"github.com/gorilla/websocket"
	"github.com/lestrrat-go/jwx/jwk"
	"github.com/lestrrat-go/jwx/jwt"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"golang.org/x/time/rate"
)

var upgrader = websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }}

// Prometheus metrics
var (
	httpRequests = prometheus.NewCounterVec(prometheus.CounterOpts{
		Name: "gateway_http_requests_total",
		Help: "Total HTTP requests processed.",
	}, []string{"path", "method", "status"})
	wsConnections = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "gateway_ws_connections_total",
		Help: "Total successful websocket connections.",
	})
	tokenValidationFailures = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "gateway_token_validation_failures_total",
		Help: "Total token validation failures.",
	})
)

func init() {
	prometheus.MustRegister(httpRequests, wsConnections, tokenValidationFailures)
}

// JWKS client as before
type JWKSClient struct {
	mu       sync.Mutex
	set      jwk.Set
	url      string
	last     time.Time
	ttl      time.Duration
	inflight bool
}

func NewJWKSClient(url string, ttl time.Duration) *JWKSClient {
	return &JWKSClient{url: url, ttl: ttl}
}

func (c *JWKSClient) get(ctx context.Context) (jwk.Set, error) {
	c.mu.Lock()
	if c.set != nil && time.Since(c.last) < c.ttl {
		s := c.set
		c.mu.Unlock()
		return s, nil
	}
	if c.inflight {
		c.mu.Unlock()
		time.Sleep(200 * time.Millisecond)
		return c.get(ctx)
	}
	c.inflight = true
	c.mu.Unlock()

	set, err := jwk.Fetch(ctx, c.url)
	c.mu.Lock()
	if err == nil {
		c.set = set
		c.last = time.Now()
	}
	c.inflight = false
	c.mu.Unlock()
	return c.set, err
}

func (c *JWKSClient) ValidateToken(ctx context.Context, tokenString string) (jwt.Token, error) {
	if c.url == "" {
		return nil, nil
	}
	set, err := c.get(ctx)
	if err != nil {
		return nil, fmt.Errorf("jwks fetch: %w", err)
	}
	tok, err := jwt.ParseString(tokenString, jwt.WithKeySet(set))
	if err != nil {
		return nil, fmt.Errorf("jwt parse/verify: %w", err)
	}
	if exp, ok := tok.Expiration(); ok {
		if time.Now().After(exp) {
			return nil, errors.New("token expired")
		}
	}
	return tok, nil
}

// In-memory rate limiter store (fallback)
type RateLimiterStore struct {
	mu   sync.Mutex
	data map[string]*rate.Limiter
	r    rate.Limit
	b    int
}

func NewRateLimiterStore(r rate.Limit, b int) *RateLimiterStore {
	return &RateLimiterStore{data: make(map[string]*rate.Limiter), r: r, b: b}
}

func (s *RateLimiterStore) Get(ip string) *rate.Limiter {
	s.mu.Lock()
	defer s.mu.Unlock()
	lim, ok := s.data[ip]
	if !ok {
		lim = rate.NewLimiter(s.r, s.b)
		s.data[ip] = lim
	}
	return lim
}

// Redis-backed limiter: simple token bucket approximation using INCR with expiry
type RedisLimiter struct {
	client *redis.Client
	rate   int // requests per second
	burst  int
}

func NewRedisLimiter(redisURL string, rateVal, burstVal int) (*RedisLimiter, error) {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, err
	}
	client := redis.NewClient(opt)
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}
	return &RedisLimiter{client: client, rate: rateVal, burst: burstVal}, nil
}

func (r *RedisLimiter) Allow(ip string) bool {
	// key with one-second window
	ctx := context.Background()
	key := "rl:" + ip + ":" + time.Now().Format("2006-01-02T15:04:05")
	// increment count
	val, err := r.client.Incr(ctx, key).Result()
	if err != nil {
		// on error, allow to avoid blocking legitimate traffic
		return true
	}
	if val == 1 {
		// set expiry 2s for safety
		r.client.Expire(ctx, key, 2*time.Second)
	}
	limit := int64(r.rate + r.burst)
	if val > limit {
		return false
	}
	return true
}

// callNakamaValidate as before
func callNakamaValidate(nakamaRPCUrl, httpKey, token string) (map[string]interface{}, error) {
	payload := map[string]string{"token": token}
	b, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", nakamaRPCUrl+"?http_key="+httpKey, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		return nil, fmt.Errorf("nakama rpc status=%d body=%s", resp.StatusCode, string(body))
	}
	var out map[string]interface{}
	dec := json.NewDecoder(resp.Body)
	if err := dec.Decode(&out); err != nil {
		return nil, err
	}
	return out, nil
}

func main() {
	jwksURL := os.Getenv("JWKS_URL")
	worldWS := os.Getenv("WORLD_WS")
	if worldWS == "" {
		worldWS = "ws://world:8090/ws"
	}
	nakamaRPCUrl := os.Getenv("NAKAMA_RPC_URL")
	if nakamaRPCUrl == "" {
		nakamaRPCUrl = "http://nakama:7350/v2/rpc/validate_session"
	}
	nakamaHttpKey := os.Getenv("NAKAMA_HTTP_KEY")
	if nakamaHttpKey == "" {
		nakamaHttpKey = "defaulthttpkey"
	}

	rps := 5
	burst := 10
	if v := os.Getenv("RATE_LIMIT_RPS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil { rps = n }
	}
	if v := os.Getenv("RATE_LIMIT_BURST"); v != "" {
		if n, err := strconv.Atoi(v); err == nil { burst = n }
	}

	useRedis := false
	if os.Getenv("USE_REDIS_RATE") == "true" {
		useRedis = true
	}

	var redisLimiter *RedisLimiter = nil
	if useRedis {
		redisURL := os.Getenv("REDIS_URL")
		if redisURL == "" {
			redisURL = "redis://redis:6379/0"
		}
		rl, err := NewRedisLimiter(redisURL, rps, burst)
		if err != nil {
			log.Println("redis limiter init failed:", err, "falling back to in-memory limiter")
		} else {
			redisLimiter = rl
			log.Println("redis rate limiter enabled")
		}
	}

	jwksClient := NewJWKSClient(jwksURL, 5*time.Minute)
	memRL := NewRateLimiterStore(rate.Limit(rps), burst)

	r := chi.NewRouter()

	// metrics endpoint
	metricsPath := os.Getenv("METRICS_PATH")
	if metricsPath == "" {
		metricsPath = "/metrics"
	}
	r.Handle(metricsPath, promhttp.Handler())

	// middleware to count http requests
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			// capture response status via wrapper
			rw := &statusResponseWriter{ResponseWriter: w, status: 200}
			start := time.Now()
			next.ServeHTTP(rw, req)
			duration := time.Since(start)
			_ = duration
			httpRequests.WithLabelValues(req.URL.Path, req.Method, fmt.Sprintf("%d", rw.status)).Inc()
		})
	})

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte("ok"))
	})

	r.Get("/ws", func(w http.ResponseWriter, r *http.Request) {
		ip := clientIP(r)
		// rate limiting
		allowed := true
		if redisLimiter != nil {
			allowed = redisLimiter.Allow(ip)
		} else {
			allowed = memRL.Get(ip).Allow()
		}
		if !allowed {
			http.Error(w, "rate limit", http.StatusTooManyRequests)
			return
		}

		auth := r.Header.Get("Authorization")
		if len(auth) < 8 {
			http.Error(w, "missing Authorization header", http.StatusUnauthorized)
			tokenValidationFailures.Inc()
			return
		}
		token := auth[7:]

		tok, err := jwksClient.ValidateToken(r.Context(), token)
		if err != nil {
			http.Error(w, "token invalid: "+err.Error(), http.StatusUnauthorized)
			tokenValidationFailures.Inc()
			return
		}

		var sub interface{} = nil
		var username interface{} = nil

		if tok != nil {
			sub, _ = tok.Get("sub")
			username, _ = tok.Get("name")
		} else {
			out, err := callNakamaValidate(nakamaRPCUrl, nakamaHttpKey, token)
			if err != nil {
				http.Error(w, "nakama validate failed: "+err.Error(), http.StatusUnauthorized)
				tokenValidationFailures.Inc()
				return
			}
			if v, ok := out["valid"].(bool); !ok || !v {
				http.Error(w, "nakama: token invalid", http.StatusUnauthorized)
				tokenValidationFailures.Inc()
				return
			}
			if s, ok := out["sub"]; ok {
				sub = s
			}
			if u, ok := out["username"]; ok {
				username = u
			}
		}

		// upgrade to websocket
		clientConn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Println("upgrade error:", err)
			return
		}
		wsConnections.Inc()
		defer clientConn.Close()

		u, err := url.Parse(worldWS)
		if err != nil {
			log.Println("invalid world ws:", err)
			clientConn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseInternalServerErr, "upstream invalid"))
			return
		}
		dialer := websocket.Dialer{HandshakeTimeout: 5 * time.Second}
		upConn, _, err := dialer.Dial(u.String(), nil)
		if err != nil {
			log.Println("dial upstream:", err)
			clientConn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseInternalServerErr, "upstream unavailable"))
			return
		}
		defer upConn.Close()

		init := map[string]interface{}{"t": "auth_init"}
		if sub != nil {
			init["sub"] = sub
		}
		if username != nil {
			init["username"] = username
		}
		binit, _ := json.Marshal(init)
		upConn.WriteMessage(websocket.TextMessage, binit)

		errc := make(chan error, 2)
		go proxy(clientConn, upConn, errc)
		go proxy(upConn, clientConn, errc)
		err = <-errc
		log.Println("proxy finished:", err)
	})

	addr := ":8080"
	log.Println("Gateway listening on", addr, "-> world:", os.Getenv("WORLD_WS"))
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatal(err)
	}
}

func proxy(src, dst *websocket.Conn, errc chan error) {
	for {
		mt, msg, err := src.ReadMessage()
		if err != nil {
			errc <- err
			return
		}
		if len(msg) > 1<<20 {
			errc <- fmt.Errorf("message too large")
			return
		}
		if err := dst.WriteMessage(mt, msg); err != nil {
			errc <- err
			return
		}
	}
}

type statusResponseWriter struct {
	http.ResponseWriter
	status int
}

func (w *statusResponseWriter) WriteHeader(code int) {
	w.status = code
	w.ResponseWriter.WriteHeader(code)
}

func clientIP(r *http.Request) string {
	if h := r.Header.Get("X-Real-IP"); h != "" {
		return h
	}
	if h := r.Header.Get("X-Forwarded-For"); h != "" {
		return h
	}
	host, _, _ := net.SplitHostPort(r.RemoteAddr)
	return host
}
