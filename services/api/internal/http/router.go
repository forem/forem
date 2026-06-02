package httpapi

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/agentwego/noema/services/api/internal/config"
	"github.com/agentwego/noema/services/api/internal/search"
)

func NewRouter(cfg config.Config, searchProvider search.Provider) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", healthHandler(cfg, searchProvider))
	mux.HandleFunc("/search", searchHandler(searchProvider))
	mux.HandleFunc("/", notFoundHandler())
	return mux
}

func healthHandler(cfg config.Config, searchProvider search.Provider) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":          "ok",
			"service":         "noema-api",
			"env":             cfg.Env,
			"search_provider": searchProvider.Name(),
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
		if strings.TrimSpace(r.URL.Query().Get("q")) == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "missing query"})
			return
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

func notFoundHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "not found"})
	}
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
