package config_test

import (
	"testing"

	"github.com/agentwego/noema/services/api/internal/config"
)

func TestLoadDefaultsAreProductionSafeForLocalSkeleton(t *testing.T) {
	t.Setenv("NOEMA_ENV", "")
	t.Setenv("PORT", "")
	t.Setenv("SEARCH_PROVIDER", "")
	t.Setenv("ELASTICSEARCH_INDEX_PREFIX", "")

	cfg := config.Load()

	if cfg.Env != "development" {
		t.Fatalf("Env = %q, want development", cfg.Env)
	}
	if cfg.HTTP.Port != "8080" {
		t.Fatalf("HTTP.Port = %q, want 8080", cfg.HTTP.Port)
	}
	if cfg.Search.Provider != "postgres" {
		t.Fatalf("Search.Provider = %q, want postgres fallback", cfg.Search.Provider)
	}
	if cfg.Search.IndexPrefix != "noema" {
		t.Fatalf("Search.IndexPrefix = %q, want noema", cfg.Search.IndexPrefix)
	}
}

func TestLoadReadsExplicitSearchBoundaryEnv(t *testing.T) {
	t.Setenv("NOEMA_ENV", "test")
	t.Setenv("PORT", "9090")
	t.Setenv("SEARCH_PROVIDER", "elasticsearch")
	t.Setenv("ELASTICSEARCH_INDEX_PREFIX", "noema-ci")

	cfg := config.Load()

	if cfg.Env != "test" {
		t.Fatalf("Env = %q, want test", cfg.Env)
	}
	if cfg.HTTP.Port != "9090" {
		t.Fatalf("HTTP.Port = %q, want 9090", cfg.HTTP.Port)
	}
	if cfg.Search.Provider != "elasticsearch" {
		t.Fatalf("Search.Provider = %q, want elasticsearch", cfg.Search.Provider)
	}
	if cfg.Search.IndexPrefix != "noema-ci" {
		t.Fatalf("Search.IndexPrefix = %q, want noema-ci", cfg.Search.IndexPrefix)
	}
}
