package elastic_test

import (
	"context"
	"encoding/json"
	"strings"
	"testing"

	"github.com/agentwego/noema/services/api/internal/search"
	"github.com/agentwego/noema/services/api/internal/search/elastic"
)

func TestElasticsearchProviderRequiresExplicitTransport(t *testing.T) {
	if _, err := search.NewProvider("elasticsearch", search.ProviderOptions{}); err == nil {
		t.Fatal("expected elasticsearch provider to require an explicit local/test transport")
	}
}

func TestElasticsearchProviderEnsureIndexesUsesMockableTransport(t *testing.T) {
	transport := &fakeTransport{}
	provider := newTestProvider(t, transport)

	if err := provider.EnsureIndexes(context.Background()); err != nil {
		t.Fatalf("EnsureIndexes() error = %v", err)
	}

	if len(transport.requests) != 8 {
		t.Fatalf("EnsureIndexes made %d requests, want 8 create/alias requests", len(transport.requests))
	}
	first := transport.requests[0]
	if first.Method != "PUT" || first.Path != "/noema-articles-v1" {
		t.Fatalf("first request = %s %s, want PUT /noema-articles-v1", first.Method, first.Path)
	}
	var createBody map[string]any
	if err := json.Unmarshal(first.Body, &createBody); err != nil {
		t.Fatalf("create index body must be JSON: %v\n%s", err, string(first.Body))
	}
	mappings := createBody["mappings"].(map[string]any)
	if mappings["dynamic"] != "strict" {
		t.Fatalf("mapping dynamic = %v, want strict", mappings["dynamic"])
	}

	second := transport.requests[1]
	if second.Method != "POST" || second.Path != "/_aliases" {
		t.Fatalf("second request = %s %s, want POST /_aliases", second.Method, second.Path)
	}
	if !strings.Contains(string(second.Body), "noema-articles-read") || !strings.Contains(string(second.Body), "noema-articles-write") {
		t.Fatalf("alias request does not point read/write aliases: %s", string(second.Body))
	}
}

func TestElasticsearchProviderBulkIndexUsesWriteAliasesAndNDJSON(t *testing.T) {
	transport := &fakeTransport{}
	provider := newTestProvider(t, transport)

	err := provider.BulkIndex(context.Background(), []search.Document{
		search.ArticleDocument{ID: "a1", Title: "中文 Go Native"},
		search.UserDocument{ID: "u1", Username: "alice", Name: "Alice"},
	})
	if err != nil {
		t.Fatalf("BulkIndex() error = %v", err)
	}

	if len(transport.requests) != 1 {
		t.Fatalf("BulkIndex made %d requests, want 1", len(transport.requests))
	}
	req := transport.requests[0]
	if req.Method != "POST" || req.Path != "/_bulk" {
		t.Fatalf("bulk request = %s %s, want POST /_bulk", req.Method, req.Path)
	}
	body := string(req.Body)
	for _, want := range []string{"\"_index\":\"noema-articles-write\"", "\"_id\":\"a1\"", "\"title\":\"中文 Go Native\"", "\"_index\":\"noema-users-write\"", "\"username\":\"alice\""} {
		if !strings.Contains(body, want) {
			t.Fatalf("bulk body missing %s: %s", want, body)
		}
	}
	if !strings.HasSuffix(body, "\n") {
		t.Fatalf("bulk body must end with newline: %q", body)
	}
}

func TestElasticsearchProviderSearchParsesHitsFromMockTransport(t *testing.T) {
	transport := &fakeTransport{
		responses: []search.TransportResponse{{
			StatusCode: 200,
			Body: []byte(`{
			  "hits": {"hits": [
			    {"_index": "noema-articles-v1", "_id": "a1", "_source": {"title": "中文 Go Native"}},
			    {"_index": "noema-users-v1", "_id": "u1", "_source": {"username": "alice", "name": "Alice"}}
			  ]}
			}`),
		}},
	}
	provider := newTestProvider(t, transport)

	result, err := provider.Search(context.Background(), search.SearchRequest{Query: "  中文 Go  ", Limit: 500})
	if err != nil {
		t.Fatalf("Search() error = %v", err)
	}
	if result.Provider != "elasticsearch" || result.Query != "中文 Go" || result.Limit != search.MaxSearchLimit {
		t.Fatalf("result = %#v, want normalized elasticsearch result", result)
	}
	if len(result.Hits) != 2 || result.Hits[0].Family != search.DocumentFamilyArticles || result.Hits[0].ID != "a1" || result.Hits[0].Title != "中文 Go Native" {
		t.Fatalf("hits = %#v", result.Hits)
	}
	if result.Hits[1].Family != search.DocumentFamilyUsers || result.Hits[1].ID != "u1" || result.Hits[1].Title != "Alice" {
		t.Fatalf("user hit = %#v", result.Hits[1])
	}

	if len(transport.requests) != 1 {
		t.Fatalf("Search made %d requests, want 1", len(transport.requests))
	}
	req := transport.requests[0]
	if req.Method != "POST" || req.Path != "/noema-articles-read,noema-comments-read,noema-users-read,noema-tags-read/_search" {
		t.Fatalf("search request = %s %s, want POST all read aliases/_search", req.Method, req.Path)
	}
	if !strings.Contains(string(req.Body), "中文 Go") || !strings.Contains(string(req.Body), "100") {
		t.Fatalf("search body should contain normalized query and limit: %s", string(req.Body))
	}
}

func newTestProvider(t *testing.T, transport *fakeTransport) search.Provider {
	t.Helper()
	provider, err := elastic.NewProvider(search.ProviderOptions{
		IndexFamily: search.IndexFamily{Prefix: "noema", Version: "v1"},
		Analyzer:    elastic.AnalyzerNGram,
		Transport:   transport,
	})
	if err != nil {
		t.Fatalf("NewProvider() error = %v", err)
	}
	return provider
}

type fakeTransport struct {
	requests  []search.TransportRequest
	responses []search.TransportResponse
}

func (f *fakeTransport) Do(_ context.Context, req search.TransportRequest) (search.TransportResponse, error) {
	f.requests = append(f.requests, req)
	if len(f.responses) > 0 {
		response := f.responses[0]
		f.responses = f.responses[1:]
		return response, nil
	}
	return search.TransportResponse{StatusCode: 200, Body: []byte(`{"acknowledged":true}`)}, nil
}
