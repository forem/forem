package main

import (
	"context"
	"testing"

	"github.com/agentwego/noema/services/api/internal/config"
	"github.com/agentwego/noema/services/api/internal/search"
)

func TestBuildSearchProviderFallsBackToNoopWhenConfiguredProviderUnavailableInTestEnv(t *testing.T) {
	cfg := config.Config{Env: "test", Search: config.SearchConfig{Provider: "does-not-exist"}}

	provider, err := buildSearchProvider(cfg)
	if err != nil {
		t.Fatalf("test fallback provider returned error: %v", err)
	}
	result, err := provider.Search(context.Background(), search.SearchRequest{})
	if err != nil {
		t.Fatalf("fallback provider search returned error: %v", err)
	}
	if result.Provider != "noop" || provider.Name() != "noop" {
		t.Fatalf("provider = %q result provider = %q, want noop", provider.Name(), result.Provider)
	}
}

func TestBuildSearchProviderRejectsUnavailableProviderOutsideLocalEnv(t *testing.T) {
	cfg := config.Config{Env: "production", Search: config.SearchConfig{Provider: "does-not-exist"}}

	provider, err := buildSearchProvider(cfg)
	if err == nil {
		t.Fatalf("buildSearchProvider returned provider %v, want error outside local/test env", provider)
	}
}

func TestBuildSearchProviderUsesConfiguredProviderWhenAvailable(t *testing.T) {
	cfg := config.Config{Env: "production", Search: config.SearchConfig{Provider: "postgres"}}

	provider, err := buildSearchProvider(cfg)
	if err != nil {
		t.Fatalf("postgres provider returned error: %v", err)
	}
	result, err := provider.Search(context.Background(), search.SearchRequest{})
	if err != nil {
		t.Fatalf("postgres provider search returned error: %v", err)
	}
	if result.Provider != "postgres" || provider.Name() != "postgres" {
		t.Fatalf("provider = %q result provider = %q, want postgres", provider.Name(), result.Provider)
	}
}
