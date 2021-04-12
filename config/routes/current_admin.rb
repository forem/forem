# NOTE: @ridhwana These routes below will be deleted once we remove the
# admin_restructure feature flag, hence they've been regrouped in this manner.
resources :articles, only: %i[index show update]
resources :badges, only: %i[index edit update new create]
resources :badge_achievements, only: %i[index destroy]
get "/badge_achievements/award_badges", to: "badge_achievements#award"
post "/badge_achievements/award_badges", to: "badge_achievements#award_badges"
resources :broadcasts
resources :chat_channels, only: %i[index create update destroy] do
  member do
    delete :remove_user
  end
end
resources :comments, only: [:index]
resource :config
resources :display_ads, only: %i[index edit update new create destroy]
resources :events, only: %i[index create update new edit]
resources :feedback_messages, only: %i[index show]
resources :html_variants, only: %i[index edit update new create show destroy]
resources :listings, only: %i[index edit update destroy]
resources :listing_categories, only: %i[index edit update new create
                                        destroy], path: "listings/categories"
resources :navigation_links, only: %i[index update create destroy]
resources :organizations, only: %i[index show] do
  member do
    patch "update_org_credits"
  end
end
resources :pages, only: %i[index new create edit update destroy]
resources :podcasts, only: %i[index edit update destroy] do
  member do
    post :fetch
    post :add_owner
  end
end
resources :mods, only: %i[index update]
resources :moderator_actions, only: %i[index]
resources :navigation_links, only: %i[index update create destroy]
resources :privileged_reactions, only: %i[index]
resources :reports, only: %i[index show], controller: "feedback_messages" do
  collection do
    post "send_email"
    post "create_note"
    post "save_status"
  end
end
resources :response_templates, only: %i[index new edit create update destroy]
resources :secrets, only: %i[index]
put "secrets", to: "secrets#update"
resources :sponsorships, only: %i[index edit update new create destroy]

resources :tags, only: %i[index new create update edit] do
  resource :moderator, only: %i[create destroy], module: "tags"
end
resources :tools, only: %i[index create] do
  collection do
    post "bust_cache"
  end
end
resources :webhook_endpoints, only: :index
resources :welcome, only: %i[index create]

# We do not expose the Data Update Scripts to all Forems by default.
constraints(->(_request) { FeatureFlag.enabled?(:data_update_scripts) }) do
  resources :data_update_scripts, only: %i[index show] do
    member do
      post :force_run
    end
  end
end

# NOTE: @citizen428 The next two resources have a temporary constraint
# while profile generalization is still WIP
constraints(->(_request) { FeatureFlag.enabled?(:profile_admin) }) do
  resources :profile_field_groups, only: %i[update create destroy]
  resources :profile_fields, only: %i[index update create destroy]
end
# @ridhwana end of routes that will be deleted once we remove the admin_restructure feature flag
