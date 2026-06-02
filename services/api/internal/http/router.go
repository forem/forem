package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/agentwego/noema/services/api/internal/config"
	"github.com/agentwego/noema/services/api/internal/search"
)

func NewRouter(cfg config.Config, searchProvider search.Provider) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", healthHandler(cfg, searchProvider))
	return mux
}

func healthHandler(cfg config.Config, searchProvider search.Provider) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":          "ok",
			"service":         "noema-api",
			"env":             cfg.Env,
			"search_provider": cfg.Search.Provider,
		})
	}
}
