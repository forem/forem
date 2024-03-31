namespace :admin do
  resources :users, only: [:create]
end

resources :articles, only: %i[index show create update] do
  collection do
    get "/search", to: "articles#search"
    get "me(/:status)", to: "articles#me", constraints: { status: /published|unpublished|all/ }
    get "/:username/:slug", to: "articles#show_by_slug"
    get "/latest", to: "articles#index", defaults: { sort: "desc" }
  end
end

resources :comments, only: %i[index show]
resources :videos, only: [:index]
resources :podcast_episodes, only: [:index]
resources :users, only: %i[show] do
  collection do
    get :me
  end
end
resources :tags, only: [:index]
resources :follows, only: [:create] do
  collection do
    get :tags
  end
end
namespace :followers do
  get :users
  get :organizations
end
resources :readinglist, only: [:index]

get "/analytics/totals", to: "analytics#totals"
get "/analytics/historical", to: "analytics#historical"
get "/analytics/past_day", to: "analytics#past_day"
get "/analytics/referrers", to: "analytics#referrers"

resources :health_checks, only: [] do
  collection do
    get :app
    get :database
    get :cache
  end
end

resources :profile_images, only: %i[show], param: :username

# The show route now handles the conventional "by id" lookup as well as by `username` (original way),
# so nested resources look up a param called organization_id_or_slug for now. (`username` is an alias for `slug`)
# Later on we may wish to refactor to a show route (and namespace for nested routes)
# that assumes an id has been given but can lookup by username if a query param is provided.
# however, this might cause friction with a consumer accustomed to lookups by username,
# so we may want to communicate such a change in advance before implementing it.
resources :organizations, only: [:show], param: :id_or_slug do
  resources :users, only: [:index], to: "organizations#users"
  resources :articles, only: [:index], to: "organizations#articles"
end

resource :instance, only: %i[show]

constraints(RailsEnvConstraint.new(allowed_envs: %w[test])) do
  resource :feature_flags, only: %i[create show destroy], param: :flag
end
