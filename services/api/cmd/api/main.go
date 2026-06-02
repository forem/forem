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
	searchProvider := buildSearchProvider(cfg)
	router := httpapi.NewRouter(cfg, searchProvider)
	addr := ":" + cfg.HTTP.Port

	slog.Info("starting noema api", "addr", addr, "env", cfg.Env, "search_provider", searchProvider.Name())
	if err := http.ListenAndServe(addr, router); err != nil {
		slog.Error("noema api stopped", "error", err)
		os.Exit(1)
	}
}

func buildSearchProvider(cfg config.Config) search.Provider {
	searchProvider, err := search.NewProvider(cfg.Search.Provider, search.ProviderOptions{})
	if err != nil {
		slog.Warn("search provider unavailable; falling back to noop", "provider", cfg.Search.Provider, "error", err)
		return search.NewNoopProvider()
	}
	return searchProvider
}
