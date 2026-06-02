package main

import (
	"context"
	"testing"

	"github.com/agentwego/noema/services/api/internal/config"
	"github.com/agentwego/noema/services/api/internal/search"
)

func TestBuildSearchProviderFallsBackToNoopWhenConfiguredProviderUnavailable(t *testing.T) {
	cfg := config.Config{Search: config.SearchConfig{Provider: "does-not-exist"}}

	provider := buildSearchProvider(cfg)
	result, err := provider.Search(context.Background(), search.SearchRequest{})
	if err != nil {
		t.Fatalf("fallback provider search returned error: %v", err)
	}
	if result.Provider != "noop" || provider.Name() != "noop" {
		t.Fatalf("provider = %q result provider = %q, want noop", provider.Name(), result.Provider)
	}
}

func TestBuildSearchProviderUsesConfiguredProviderWhenAvailable(t *testing.T) {
	cfg := config.Config{Search: config.SearchConfig{Provider: "postgres"}}

	provider := buildSearchProvider(cfg)
	result, err := provider.Search(context.Background(), search.SearchRequest{})
	if err != nil {
		t.Fatalf("postgres provider search returned error: %v", err)
	}
	if result.Provider != "postgres" || provider.Name() != "postgres" {
		t.Fatalf("provider = %q result provider = %q, want postgres", provider.Name(), result.Provider)
	}
}
