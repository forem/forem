package main

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/agentwego/noema/services/api/internal/config"
	httpapi "github.com/agentwego/noema/services/api/internal/http"
	"github.com/agentwego/noema/services/api/internal/search"
)

func main() {
	cfg := config.Load()
	router := httpapi.NewRouter(cfg, search.NewNoopProvider())
	addr := ":" + cfg.HTTP.Port

	slog.Info("starting noema api", "addr", addr, "env", cfg.Env, "search_provider", cfg.Search.Provider)
	if err := http.ListenAndServe(addr, router); err != nil {
		slog.Error("noema api stopped", "error", err)
		os.Exit(1)
	}
}
