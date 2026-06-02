package config

import "os"

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
	Provider    string
	IndexPrefix string
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
			Provider:    envOr("SEARCH_PROVIDER", "postgres"),
			IndexPrefix: envOr("ELASTICSEARCH_INDEX_PREFIX", "noema"),
		},
	}
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
