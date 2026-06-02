package httpapi_test

import (
	"bytes"
	"encoding/json"
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

func TestRouterReturnsNotFoundForUnknownRoute(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/does-not-exist", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", res.Code)
	}
}
