package httpapi_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/agentwego/noema/services/api/internal/config"
	httpapi "github.com/agentwego/noema/services/api/internal/http"
	"github.com/agentwego/noema/services/api/internal/search"
)

func TestRouterExposesLocalHealthWithoutExternalDependencies(t *testing.T) {
	cfg := config.Config{
		Env:    "test",
		HTTP:   config.HTTPConfig{Port: "0"},
		Search: config.SearchConfig{Provider: "postgres", IndexPrefix: "noema"},
	}
	router := httpapi.NewRouter(cfg, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", res.Code, res.Body.String())
	}

	var body map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("health response is not JSON: %v", err)
	}
	if body["status"] != "ok" {
		t.Fatalf("status field = %q, want ok", body["status"])
	}
	if body["service"] != "noema-api" {
		t.Fatalf("service field = %q, want noema-api", body["service"])
	}
	if body["search_provider"] != "noop" {
		t.Fatalf("search_provider field = %q, want actual provider noop", body["search_provider"])
	}
}

func TestRouterSearchEndpointUsesProviderAndNormalizesRequest(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/search?q=%20%20go%20native%20%20&limit=250", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", res.Code, res.Body.String())
	}

	var body struct {
		Provider string `json:"provider"`
		Query    string `json:"query"`
		Limit    int    `json:"limit"`
		Hits     []struct {
			Family string `json:"family"`
			ID     string `json:"id"`
			Title  string `json:"title"`
		} `json:"hits"`
	}
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("search response is not JSON: %v", err)
	}
	if body.Provider != "noop" || body.Query != "go native" || body.Limit != search.MaxSearchLimit {
		t.Fatalf("search response = provider %q query %q limit %d, want noop/go native/%d", body.Provider, body.Query, body.Limit, search.MaxSearchLimit)
	}
	if !bytes.Contains(res.Body.Bytes(), []byte(`"provider"`)) || bytes.Contains(res.Body.Bytes(), []byte(`"Provider"`)) {
		t.Fatalf("search response JSON keys are not lowercase contract keys: %s", res.Body.String())
	}
	if body.Hits == nil || len(body.Hits) != 0 {
		t.Fatalf("hits = %#v, want empty JSON array", body.Hits)
	}
}

func TestRouterSearchEndpointRejectsNonIntegerLimit(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/search?q=go&limit=not-a-number", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400; body=%s", res.Code, res.Body.String())
	}

	var body map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("error response is not JSON: %v", err)
	}
	if body["error"] != "invalid limit" {
		t.Fatalf("error = %q, want invalid limit", body["error"])
	}
}

func TestRouterSearchEndpointRejectsEmptyQuery(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/search?q=%20%20&limit=20", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400; body=%s", res.Code, res.Body.String())
	}

	var body map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("error response is not JSON: %v", err)
	}
	if body["error"] != "missing query" {
		t.Fatalf("error = %q, want missing query", body["error"])
	}
}

func TestRouterSearchEndpointReturnsStableJSONWhenProviderFails(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, failingSearchProvider{Provider: search.NewNoopProvider()})

	req := httptest.NewRequest(http.MethodGet, "/search?q=go", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503; body=%s", res.Code, res.Body.String())
	}
	if bytes.Contains(res.Body.Bytes(), []byte("internal backend detail")) {
		t.Fatalf("search error leaked provider detail: %s", res.Body.String())
	}

	var body map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("error response is not JSON: %v", err)
	}
	if body["error"] != "search unavailable" {
		t.Fatalf("error = %q, want search unavailable", body["error"])
	}
}

func TestRouterSearchEndpointReturnsJSONForUnsupportedMethod(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodPost, "/search", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want 405; body=%s", res.Code, res.Body.String())
	}

	var body map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("method error response is not JSON: %v; body=%s", err, res.Body.String())
	}
	if body["error"] != "method not allowed" {
		t.Fatalf("error = %q, want method not allowed", body["error"])
	}
}

func TestRouterReturnsNotFoundForUnknownRoute(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/does-not-exist", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", res.Code)
	}
}

type failingSearchProvider struct {
	search.Provider
}

func (p failingSearchProvider) Search(_ context.Context, _ search.SearchRequest) (*search.SearchResult, error) {
	return nil, errors.New("internal backend detail")
}
