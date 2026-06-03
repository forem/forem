package config

import (
	"os"
	"strconv"
)

// Config is the native Noema API configuration boundary. Keep it explicit so
// the Go service does not inherit Rails global runtime state by accident.
type Config struct {
	Env      string
	HTTP     HTTPConfig
	Search   SearchConfig
	Database DatabaseConfig
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

type DatabaseConfig struct {
	URL string
}

// Load reads explicit process settings for the native skeleton. Secret-bearing
// values such as database DSNs may be supplied by environment/Secret handoff at
// runtime, but defaults remain empty so local verification never requires or
// prints real credentials.
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
		Database: DatabaseConfig{
			URL: envOr("NOEMA_DATABASE_URL", ""),
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
