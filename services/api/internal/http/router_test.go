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

func TestRouterHealthEndpointReturnsJSONForUnsupportedMethod(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodPost, "/healthz", nil)
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

func TestRouterLegacyImportPreviewBuildsLocalPlanWithoutExternalDependencies(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())
	payload := `{
		"article": {
			"id": 123459,
			"user_id": 42,
			"title": "Composed Import Preview",
			"body_markdown": "Preview body for the composed import bundle.",
			"slug": "composed-import-preview",
			"published": true,
			"published_at": "2026-06-03T03:00:00Z",
			"created_at": "2026-06-03T02:30:00Z",
			"updated_at": "2026-06-03T03:05:00Z",
			"cached_tag_list": "go, native"
		},
		"user": {
			"id": 42,
			"username": "alice",
			"name": "Alice Example",
			"profile_image": "https://example.com/avatar.png",
			"created_at": "2026-06-03T00:00:00Z",
			"updated_at": "2026-06-03T01:30:00Z"
		},
		"email": "alice@example.com",
		"external_identities": [{"provider": "github", "uid": "alice-gh"}]
	}`

	req := httptest.NewRequest(http.MethodPost, "/legacy-import/preview", bytes.NewBufferString(payload))
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", res.Code, res.Body.String())
	}
	if bytes.Contains(res.Body.Bytes(), []byte(`"ID"`)) || bytes.Contains(res.Body.Bytes(), []byte(`"SchemaVersion"`)) {
		t.Fatalf("legacy import preview leaked Go exported JSON keys: %s", res.Body.String())
	}

	var body struct {
		SchemaVersion string `json:"schema_version"`
		Bundle        struct {
			User struct {
				ID       string `json:"id"`
				Username string `json:"username"`
			} `json:"user"`
			Article struct {
				ID       string   `json:"id"`
				AuthorID string   `json:"author_id"`
				Tags     []string `json:"tags"`
			} `json:"article"`
		} `json:"bundle"`
		Kratos struct {
			Identity struct {
				ID             string            `json:"id"`
				MetadataAdmin  map[string]string `json:"metadata_admin"`
				MetadataPublic map[string]string `json:"metadata_public"`
			} `json:"identity"`
			Session struct {
				Active     bool   `json:"active"`
				IdentityID string `json:"identity_id"`
			} `json:"session"`
			SelfServiceFlows []struct {
				Kind string `json:"type"`
			} `json:"self_service_flows"`
		} `json:"kratos"`
		SideEffects string `json:"side_effects"`
	}
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("preview response is not JSON: %v; body=%s", err, res.Body.String())
	}
	if body.SchemaVersion != "noema.legacy-import.preview/v1" || body.Bundle.User.ID != "42" || body.Bundle.Article.AuthorID != "42" {
		t.Fatalf("unexpected preview body: %+v", body)
	}
	if body.Kratos.Identity.ID != "kratos-preview-identity-42" || body.Kratos.Identity.MetadataAdmin["legacy_identity_github"] != "github:alice-gh" {
		t.Fatalf("unexpected Kratos identity preview: %+v", body.Kratos.Identity)
	}
	if !body.Kratos.Session.Active || body.Kratos.Session.IdentityID != body.Kratos.Identity.ID || len(body.Kratos.SelfServiceFlows) != 5 {
		t.Fatalf("unexpected Kratos session/flow preview: %+v", body.Kratos)
	}
	if body.SideEffects != "none-local-preview-only" {
		t.Fatalf("side_effects = %q", body.SideEffects)
	}
}

func TestRouterLegacyImportBatchPreviewBuildsMixedLocalPlan(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())
	payload := `{
		"items": [
			{
				"article": {
					"id": 123459,
					"user_id": 42,
					"title": "Composed Import Preview",
					"body_markdown": "Preview body for the composed import bundle.",
					"slug": "composed-import-preview",
					"published": true,
					"published_at": "2026-06-03T03:00:00Z",
					"created_at": "2026-06-03T02:30:00Z",
					"updated_at": "2026-06-03T03:05:00Z",
					"cached_tag_list": "go, native"
				},
				"user": {
					"id": 42,
					"username": "alice",
					"name": "Alice Example",
					"profile_image": "https://example.com/avatar.png",
					"created_at": "2026-06-03T00:00:00Z",
					"updated_at": "2026-06-03T01:30:00Z"
				},
				"email": "alice@example.com",
				"external_identities": [{"provider": "github", "uid": "alice-gh"}]
			},
			{
				"article": {
					"id": 123460,
					"user_id": 43,
					"title": "Broken Import Preview",
					"body_markdown": "This item intentionally omits slug.",
					"published": true,
					"published_at": "2026-06-03T03:00:00Z",
					"created_at": "2026-06-03T02:30:00Z",
					"updated_at": "2026-06-03T03:05:00Z",
					"cached_tag_list": "broken"
				},
				"user": {"id": 43, "username": "bob", "name": "Bob Example"},
				"email": "bob@example.com"
			}
		]
	}`

	req := httptest.NewRequest(http.MethodPost, "/legacy-import/batch-preview", bytes.NewBufferString(payload))
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", res.Code, res.Body.String())
	}
	if bytes.Contains(res.Body.Bytes(), []byte(`"ID"`)) || bytes.Contains(res.Body.Bytes(), []byte(`"SchemaVersion"`)) || bytes.Contains(res.Body.Bytes(), []byte(`"Preview"`)) {
		t.Fatalf("batch preview leaked Go exported JSON keys: %s", res.Body.String())
	}

	var body struct {
		SchemaVersion string `json:"schema_version"`
		Total         int    `json:"total"`
		Succeeded     int    `json:"succeeded"`
		Failed        int    `json:"failed"`
		Items         []struct {
			Index   int    `json:"index"`
			Error   string `json:"error,omitempty"`
			Preview *struct {
				Bundle struct {
					User struct {
						ID string `json:"id"`
					} `json:"user"`
					Article struct {
						ID string `json:"id"`
					} `json:"article"`
				} `json:"bundle"`
				Kratos struct {
					Identity struct {
						ID string `json:"id"`
					} `json:"identity"`
					OperationPlans []struct {
						Surface   string `json:"surface"`
						Method    string `json:"method"`
						Path      string `json:"path"`
						Execution string `json:"execution"`
					} `json:"operation_plans"`
				} `json:"kratos"`
				SideEffects string `json:"side_effects"`
			} `json:"preview,omitempty"`
		} `json:"items"`
		SideEffects string `json:"side_effects"`
	}
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("batch preview response is not JSON: %v; body=%s", err, res.Body.String())
	}
	if body.SchemaVersion != "noema.legacy-import.batch-preview/v1" || body.Total != 2 || body.Succeeded != 1 || body.Failed != 1 || len(body.Items) != 2 {
		t.Fatalf("unexpected batch preview counts: %+v", body)
	}
	if body.Items[0].Preview == nil || body.Items[0].Preview.Kratos.OperationPlans[0].Path != "/admin/identities" || body.Items[0].Preview.Kratos.OperationPlans[0].Execution != "review-only" {
		t.Fatalf("first batch item missing review-only Kratos operation plan: %+v", body.Items[0])
	}
	if body.Items[1].Preview != nil || body.Items[1].Error == "" {
		t.Fatalf("second batch item should be per-item error: %+v", body.Items[1])
	}
	if body.SideEffects != "none-local-preview-only" {
		t.Fatalf("side_effects = %q", body.SideEffects)
	}
}

func TestRouterLegacyImportBatchPreviewReturnsJSONErrors(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	badJSON := httptest.NewRequest(http.MethodPost, "/legacy-import/batch-preview", bytes.NewBufferString(`{"items":`))
	badJSONRes := httptest.NewRecorder()
	router.ServeHTTP(badJSONRes, badJSON)
	if badJSONRes.Code != http.StatusBadRequest {
		t.Fatalf("malformed batch status = %d, want 400; body=%s", badJSONRes.Code, badJSONRes.Body.String())
	}

	empty := httptest.NewRequest(http.MethodPost, "/legacy-import/batch-preview", bytes.NewBufferString(`{"items":[]}`))
	emptyRes := httptest.NewRecorder()
	router.ServeHTTP(emptyRes, empty)
	if emptyRes.Code != http.StatusUnprocessableEntity {
		t.Fatalf("empty batch status = %d, want 422; body=%s", emptyRes.Code, emptyRes.Body.String())
	}

	method := httptest.NewRequest(http.MethodGet, "/legacy-import/batch-preview", nil)
	methodRes := httptest.NewRecorder()
	router.ServeHTTP(methodRes, method)
	if methodRes.Code != http.StatusMethodNotAllowed {
		t.Fatalf("method batch status = %d, want 405; body=%s", methodRes.Code, methodRes.Body.String())
	}
}

func TestRouterLegacyImportPreviewReturnsJSONErrors(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	badJSON := httptest.NewRequest(http.MethodPost, "/legacy-import/preview", bytes.NewBufferString(`{"article":`))
	badJSONRes := httptest.NewRecorder()
	router.ServeHTTP(badJSONRes, badJSON)
	if badJSONRes.Code != http.StatusBadRequest {
		t.Fatalf("malformed status = %d, want 400; body=%s", badJSONRes.Code, badJSONRes.Body.String())
	}

	invalid := httptest.NewRequest(http.MethodPost, "/legacy-import/preview", bytes.NewBufferString(`{"article":{}}`))
	invalidRes := httptest.NewRecorder()
	router.ServeHTTP(invalidRes, invalid)
	if invalidRes.Code != http.StatusUnprocessableEntity {
		t.Fatalf("invalid status = %d, want 422; body=%s", invalidRes.Code, invalidRes.Body.String())
	}

	method := httptest.NewRequest(http.MethodGet, "/legacy-import/preview", nil)
	methodRes := httptest.NewRecorder()
	router.ServeHTTP(methodRes, method)
	if methodRes.Code != http.StatusMethodNotAllowed {
		t.Fatalf("method status = %d, want 405; body=%s", methodRes.Code, methodRes.Body.String())
	}
}

func TestRouterReturnsJSONNotFoundForUnknownRoute(t *testing.T) {
	router := httpapi.NewRouter(config.Config{}, search.NewNoopProvider())

	req := httptest.NewRequest(http.MethodGet, "/does-not-exist", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", res.Code)
	}
	if !bytes.Contains([]byte(res.Header().Get("Content-Type")), []byte("application/json")) {
		t.Fatalf("content-type = %q, want application/json", res.Header().Get("Content-Type"))
	}

	var body map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("not found response is not JSON: %v; body=%s", err, res.Body.String())
	}
	if body["error"] != "not found" {
		t.Fatalf("error = %q, want not found", body["error"])
	}
}

type failingSearchProvider struct {
	search.Provider
}

func (p failingSearchProvider) Search(_ context.Context, _ search.SearchRequest) (*search.SearchResult, error) {
	return nil, errors.New("internal backend detail")
}
