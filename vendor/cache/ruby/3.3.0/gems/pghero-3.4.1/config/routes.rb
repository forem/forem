PgHero::Engine.routes.draw do
  scope "(:database)", constraints: proc { |req| (PgHero.config["databases"].keys + [nil]).include?(req.params[:database]) } do
    get "space", to: "home#space"
    get "space/:relation", to: "home#relation_space", as: :relation_space
    get "index_bloat", to: "home#index_bloat"
    get "live_queries", to: "home#live_queries"
    get "queries", to: "home#queries"
    get "queries/:query_hash", to: "home#show_query", as: :show_query
    get "system", to: "home#system"
    get "cpu_usage", to: "home#cpu_usage"
    get "connection_stats", to: "home#connection_stats"
    get "replication_lag_stats", to: "home#replication_lag_stats"
    get "load_stats", to: "home#load_stats"
    get "free_space_stats", to: "home#free_space_stats"
    get "explain", to: "home#explain"
    get "tune", to: "home#tune"
    get "connections", to: "home#connections"
    get "maintenance", to: "home#maintenance"
    post "kill", to: "home#kill"
    post "kill_long_running_queries", to: "home#kill_long_running_queries"
    post "kill_all", to: "home#kill_all"
    post "enable_query_stats", to: "home#enable_query_stats"
    post "explain", to: "home#explain"
    post "reset_query_stats", to: "home#reset_query_stats"

    # legacy routes
    get "system_stats" => redirect("system")
    get "query_stats" => redirect("queries")

    root to: "home#index"
  end
end
