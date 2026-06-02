package httpapi_test

import (
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

func TestRouterReturnsNotFoundForUnknownRoute(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/does-not-exist", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", res.Code)
	}
}
