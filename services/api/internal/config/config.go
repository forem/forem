package config

import (
	"os"
	"strconv"
)

// Config is the native Noema API configuration boundary. Keep it explicit so
// the Go service does not inherit Rails global runtime state by accident.
type Config struct {
	Env    string
	HTTP   HTTPConfig
	Search SearchConfig
}

type HTTPConfig struct {
	Port string
}

type SearchConfig struct {
	Provider       string
	IndexPrefix    string
	BulkSize       int
	RequestTimeout string
}

// Load reads only non-secret process settings for the local skeleton. Secret
// bearing dependencies (database, Redis, Elasticsearch credentials, S3 keys)
// are intentionally out of scope until their handoff docs and rollback gates
// are complete.
func Load() Config {
	return Config{
		Env: envOr("NOEMA_ENV", "development"),
		HTTP: HTTPConfig{
			Port: envOr("PORT", "8080"),
		},
		Search: SearchConfig{
			Provider:       envOr("SEARCH_PROVIDER", "postgres"),
			IndexPrefix:    envOr("ELASTICSEARCH_INDEX_PREFIX", "noema"),
			BulkSize:       envIntOr("ELASTICSEARCH_BULK_SIZE", 500),
			RequestTimeout: envOr("ELASTICSEARCH_REQUEST_TIMEOUT", "5s"),
		},
	}
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func envIntOr(name string, fallback int) int {
	value := os.Getenv(name)
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil || parsed <= 0 {
		return fallback
	}
	return parsed
}
