namespace :admin do
  resources :users, only: [:create]
end

resources :articles, only: %i[index show create update] do
  collection do
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
resources :organizations, only: [:show], param: :username do
  resources :users, only: [:index], to: "organizations#users"
  resources :articles, only: [:index], to: "organizations#articles"
end
resource :instance, only: %i[show]

constraints(RailsEnvConstraint.new(allowed_envs: %w[test])) do
  resource :feature_flags, only: %i[create show destroy], param: :flag
end
