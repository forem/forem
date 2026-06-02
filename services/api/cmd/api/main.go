package main

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/agentwego/noema/services/api/internal/config"
	httpapi "github.com/agentwego/noema/services/api/internal/http"
	"github.com/agentwego/noema/services/api/internal/search"
	_ "github.com/agentwego/noema/services/api/internal/search/fallback"
)

func main() {
	cfg := config.Load()
	searchProvider, err := search.NewProvider(cfg.Search.Provider, search.ProviderOptions{})
	if err != nil {
		slog.Error("search provider unavailable", "provider", cfg.Search.Provider, "error", err)
		os.Exit(1)
	}
	router := httpapi.NewRouter(cfg, searchProvider)
	addr := ":" + cfg.HTTP.Port

	slog.Info("starting noema api", "addr", addr, "env", cfg.Env, "search_provider", cfg.Search.Provider)
	if err := http.ListenAndServe(addr, router); err != nil {
		slog.Error("noema api stopped", "error", err)
		os.Exit(1)
	}
}
