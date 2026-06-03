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
	if cfg.Search.BulkSize != 500 {
		t.Fatalf("Search.BulkSize = %d, want 500", cfg.Search.BulkSize)
	}
	if cfg.Search.RequestTimeout != "5s" {
		t.Fatalf("Search.RequestTimeout = %q, want 5s", cfg.Search.RequestTimeout)
	}
	if cfg.Database.URL != "" {
		t.Fatalf("Database.URL = %q, want empty default so local skeleton does not require secret-bearing DB config", cfg.Database.URL)
	}
}

func TestLoadReadsExplicitSearchBoundaryEnv(t *testing.T) {
	t.Setenv("NOEMA_ENV", "test")
	t.Setenv("PORT", "9090")
	t.Setenv("SEARCH_PROVIDER", "elasticsearch")
	t.Setenv("ELASTICSEARCH_INDEX_PREFIX", "noema-ci")
	t.Setenv("ELASTICSEARCH_BULK_SIZE", "250")
	t.Setenv("ELASTICSEARCH_REQUEST_TIMEOUT", "750ms")

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
	if cfg.Search.BulkSize != 250 {
		t.Fatalf("Search.BulkSize = %d, want 250", cfg.Search.BulkSize)
	}
	if cfg.Search.RequestTimeout != "750ms" {
		t.Fatalf("Search.RequestTimeout = %q, want 750ms", cfg.Search.RequestTimeout)
	}
}

func TestLoadReadsNativeDatabaseBoundaryEnv(t *testing.T) {
	t.Setenv("NOEMA_DATABASE_URL", "postgres://noema-local@127.0.0.1:25432/noema_test?sslmode=disable")

	cfg := config.Load()

	if cfg.Database.URL != "postgres://noema-local@127.0.0.1:25432/noema_test?sslmode=disable" {
		t.Fatalf("Database.URL = %q, want explicit native database DSN", cfg.Database.URL)
	}
}
