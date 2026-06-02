package httpapi

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/agentwego/noema/services/api/internal/config"
	"github.com/agentwego/noema/services/api/internal/search"
)

func NewRouter(cfg config.Config, searchProvider search.Provider) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", healthHandler(cfg, searchProvider))
	mux.HandleFunc("/search", searchHandler(searchProvider))
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

func searchHandler(searchProvider search.Provider) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
			return
		}

		limit := 0
		if rawLimit := r.URL.Query().Get("limit"); rawLimit != "" {
			parsedLimit, err := strconv.Atoi(rawLimit)
			if err != nil {
				writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid limit"})
				return
			}
			limit = parsedLimit
		}

		result, err := searchProvider.Search(r.Context(), search.SearchRequest{
			Query: r.URL.Query().Get("q"),
			Limit: limit,
		})
		if err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "search unavailable"})
			return
		}
		writeJSON(w, http.StatusOK, result)
	}
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
