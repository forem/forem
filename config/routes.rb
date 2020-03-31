# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  use_doorkeeper do
    controllers tokens: "oauth/tokens"
  end

  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    registrations: "registrations"
  }

  require "sidekiq/web"
  authenticated :user, ->(user) { user.tech_admin? } do
    Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
    Sidekiq::Web.set :sessions, Rails.application.config.session_options
    Sidekiq::Web.class_eval do
      use Rack::Protection, origin_whitelist: ["https://dev.to"] # resolve Rack Protection HttpOrigin
    end
    mount Sidekiq::Web => "/sidekiq"
    mount FieldTest::Engine, at: "abtests"
  end

  devise_scope :user do
    delete "/sign_out" => "devise/sessions#destroy"
    get "/enter" => "registrations#new", :as => :sign_up
  end

  namespace :admin do
    # Check administrate gem docs
    DashboardManifest::DASHBOARDS.each do |dashboard_resource|
      resources dashboard_resource
    end

    root controller: DashboardManifest::ROOT_DASHBOARD, action: :index
  end

  namespace :internal do
    get "/", to: redirect("/internal/articles")

    authenticate :user, ->(user) { user.has_role?(:tech_admin) } do
      mount Blazer::Engine, at: "blazer"
    end

    resources :articles, only: %i[index show update]
    resources :broadcasts, only: %i[index new create edit update]
    resources :buffer_updates, only: %i[create update]
    resources :classified_listings, only: %i[index edit update destroy]
    resources :comments, only: [:index]
    resources :events, only: %i[index create update]
    resources :feedback_messages, only: %i[index show]
    resources :listings, only: %i[index edit update destroy], controller: "classified_listings"
    resources :pages, only: %i[index new create edit update destroy]
    resources :mods, only: %i[index update]
    resources :moderator_actions, only: %i[index]
    resources :negative_reactions, only: %i[index]
    resources :permissions, only: %i[index]
    resources :podcasts, only: %i[index edit update destroy] do
      member do
        post :fetch
        post :add_admin
        delete :remove_admin
      end
    end
    resources :reactions, only: [:update]
    resources :response_templates, only: %i[index new edit create update destroy]
    resources :chat_channels, only: %i[index create update]
    resources :reports, only: %i[index show], controller: "feedback_messages" do
      collection do
        post "send_email"
        post "create_note"
        post "save_status"
      end
    end
    resources :tags, only: %i[index update show]
    resources :users, only: %i[index show edit update] do
      member do
        post "banish"
        post "full_delete"
        patch "user_status"
        post "merge"
        delete "remove_identity"
        post "recover_identity"
        post "send_email"
      end
    end
    resources :organization_memberships, only: %i[update destroy create]
    resources :organizations, only: %i[index show]
    resources :sponsorships, only: %i[index edit update destroy]
    resources :welcome, only: %i[index create]
    resources :growth, only: %i[index]
    resources :tools, only: %i[index create] do
      collection do
        post "bust_cache"
      end
    end
    resources :webhook_endpoints, only: :index
    resource :config
    resources :badges, only: :index
    post "badges/award_badges", to: "badges#award_badges"
  end

  namespace :stories, defaults: { format: "json" } do
    resource :feed, only: [:show] do
      get ":timeframe" => "feeds#show"
    end
  end

  namespace :api, defaults: { format: "json" } do
    scope module: :v0,
          constraints: ApiConstraints.new(version: 0, default: true) do
      resources :articles, only: %i[index show create update] do
        collection do
          get "me(/:status)", to: "articles#me", as: :me, constraints: { status: /published|unpublished|all/ }
        end
      end
      resources :comments, only: %i[index show]
      resources :videos, only: [:index]
      resources :podcast_episodes, only: [:index]
      resources :reactions, only: [:create]
      resources :users, only: %i[show] do
        collection do
          get :me
        end
      end
      resources :tags, only: [:index]
      resources :follows, only: [:create]
      namespace :followers do
        get :users
        get :organizations
      end
      resources :webhooks, only: %i[index create show destroy]

      resources :classified_listings, path: :listings, only: %i[index show create update]
      get "/listings/category/:category", to: "classified_listings#index", as: :classified_listings_category
      get "/analytics/totals", to: "analytics#totals"
      get "/analytics/historical", to: "analytics#historical"
      get "/analytics/past_day", to: "analytics#past_day"
      get "/analytics/referrers", to: "analytics#referrers"
    end
  end

  namespace :notifications do
    resources :counts, only: [:index]
    resources :reads, only: [:create]
  end

  namespace :incoming_webhooks do
    get "/mailchimp/:secret/unsubscribe", to: "mailchimp_unsubscribes#index", as: :mailchimp_unsubscribe_check
    post "/mailchimp/:secret/unsubscribe", to: "mailchimp_unsubscribes#create", as: :mailchimp_unsubscribe
  end

  resources :messages, only: [:create]
  resources :chat_channels, only: %i[index show create update]
  resources :chat_channel_memberships, only: %i[create update destroy]
  resources :articles, only: %i[update create destroy]
  resources :article_mutes, only: %i[update]
  resources :comments, only: %i[create update destroy] do
    patch "/hide", to: "comments#hide"
    patch "/unhide", to: "comments#unhide"
  end
  resources :comment_mutes, only: %i[update]
  resources :users, only: %i[index], defaults: { format: :json } # internal API
  resources :users, only: %i[update] do
    resource :twitch_stream_updates, only: %i[show create]
  end
  resources :twitch_live_streams, only: :show, param: :username
  resources :reactions, only: %i[index create]
  resources :response_templates, only: %i[create edit update destroy]
  resources :feedback_messages, only: %i[index create]
  resources :organizations, only: %i[update create]
  resources :followed_articles, only: [:index]
  resources :follows, only: %i[show create update]
  resources :image_uploads, only: [:create]
  resources :blocks
  resources :notifications, only: [:index]
  resources :tags, only: [:index] do
    collection do
      get "/onboarding", to: "tags#onboarding"
    end
  end
  resources :downloads, only: [:index]
  resources :stripe_active_cards, only: %i[create update destroy]
  resources :live_articles, only: [:index]
  resources :github_repos, only: %i[index create update] do
    collection do
      post "/update_or_create", to: "github_repos#update_or_create"
    end
  end
  resources :buffered_articles, only: [:index]
  resources :events, only: %i[index show]
  resources :additional_content_boxes, only: [:index]
  resources :videos, only: %i[index create new]
  resources :video_states, only: [:create]
  resources :twilio_tokens, only: [:show]
  resources :html_variants, only: %i[index new create show edit update]
  resources :html_variant_trials, only: [:create]
  resources :html_variant_successes, only: [:create]
  resources :tag_adjustments, only: %i[create destroy]
  resources :rating_votes, only: [:create]
  resources :page_views, only: %i[create update]
  resources :classified_listings, path: :listings, only: %i[index new create edit update destroy dashboard]
  resources :credits, only: %i[index new create] do
    get "purchase", on: :collection, to: "credits#new"
  end
  resources :buffer_updates, only: [:create]
  resources :reading_list_items, only: [:update]
  resources :poll_votes, only: %i[show create]
  resources :poll_skips, only: [:create]
  resources :profile_pins, only: %i[create update]
  resources :partnerships, only: %i[index create show], param: :option
  resources :display_ad_events, only: [:create]
  resources :badges, only: [:index]
  resource :pro_membership, path: :pro, only: %i[show create update]
  resources :user_blocks, param: :blocked_id, only: %i[show create destroy]
  resources :podcasts, only: %i[new create]
  resources :article_approvals, only: %i[create]
  resolve("ProMembership") { [:pro_membership] } # see https://guides.rubyonrails.org/routing.html#using-resolve
  namespace :followings, defaults: { format: :json } do
    get :users
    get :tags
    get :organizations
    get :podcasts
  end

  resource :onboarding, only: :show

  get "/search/tags" => "search#tags"
  get "/search/chat_channels" => "search#chat_channels"
  get "/search/classified_listings" => "search#classified_listings"
  get "/search/users" => "search#users"
  get "/search/feed_content" => "search#feed_content"
  get "/chat_channel_memberships/find_by_chat_channel_id" => "chat_channel_memberships#find_by_chat_channel_id"
  get "/listings/dashboard" => "classified_listings#dashboard"
  get "/listings/:category" => "classified_listings#index"
  get "/listings/:category/:slug" => "classified_listings#index", :as => :classified_listing_slug
  get "/listings/:category/:slug/:view" => "classified_listings#index",
      :constraints => { view: /moderate/ }
  get "/listings/:category/:slug/delete_confirm" => "classified_listings#delete_confirm"
  delete "/listings/:category/:slug" => "classified_listings#destroy"
  get "/notifications/:filter" => "notifications#index"
  get "/notifications/:filter/:org_id" => "notifications#index"
  get "/notification_subscriptions/:notifiable_type/:notifiable_id" => "notification_subscriptions#show"
  post "/notification_subscriptions/:notifiable_type/:notifiable_id" => "notification_subscriptions#upsert"
  patch "/onboarding_update" => "users#onboarding_update"
  patch "/onboarding_checkbox_update" => "users#onboarding_checkbox_update"
  get "email_subscriptions/unsubscribe"
  post "/chat_channels/:id/moderate" => "chat_channels#moderate"
  post "/chat_channels/:id/open" => "chat_channels#open"
  get "/connect" => "chat_channels#index"
  get "/connect/:slug" => "chat_channels#index"
  get "/chat_channels/:id/channel_info", to: "chat_channels#channel_info", as: :chat_channel_info
  post "/chat_channels/create_chat" => "chat_channels#create_chat"
  post "/chat_channels/block_chat" => "chat_channels#block_chat"
  delete "/messages/:id" => "messages#destroy"
  patch "/messages/:id" => "messages#update"
  get "/live/:username" => "twitch_live_streams#show"

  post "/pusher/auth" => "pusher#auth"

  get "/social_previews/article/:id" => "social_previews#article", :as => :article_social_preview
  get "/social_previews/user/:id" => "social_previews#user", :as => :user_social_preview
  get "/social_previews/organization/:id" => "social_previews#organization", :as => :organization_social_preview
  get "/social_previews/tag/:id" => "social_previews#tag", :as => :tag_social_preview
  get "/social_previews/listing/:id" => "social_previews#listing", :as => :listing_social_preview
  get "/social_previews/comment/:id" => "social_previews#comment", :as => :comment_social_preview

  get "/async_info/base_data", controller: "async_info#base_data", defaults: { format: :json }
  get "/async_info/shell_version", controller: "async_info#shell_version", defaults: { format: :json }

  get "/future", to: redirect("devteam/the-future-of-dev-160n")

  # Settings
  post "users/update_language_settings" => "users#update_language_settings"
  post "users/update_twitch_username" => "users#update_twitch_username"
  post "users/join_org" => "users#join_org"
  post "users/leave_org/:organization_id" => "users#leave_org", :as => :users_leave_org
  post "users/add_org_admin" => "users#add_org_admin"
  post "users/remove_org_admin" => "users#remove_org_admin"
  post "users/remove_from_org" => "users#remove_from_org"
  delete "users/remove_association", to: "users#remove_association"
  post "users/request_destroy", to: "users#request_destroy", as: :user_request_destroy
  get "users/confirm_destroy/:token", to: "users#confirm_destroy", as: :user_confirm_destroy
  delete "users/full_delete", to: "users#full_delete", as: :user_full_delete
  post "organizations/generate_new_secret" => "organizations#generate_new_secret"
  post "users/api_secrets" => "api_secrets#create", :as => :users_api_secrets
  delete "users/api_secrets/:id" => "api_secrets#destroy", :as => :users_api_secret

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root
  get "/about" => "pages#about"
  get "/robots.:format" => "pages#robots"
  get "/api", to: redirect("https://docs.dev.to/api")
  get "/privacy" => "pages#privacy"
  get "/terms" => "pages#terms"
  get "/contact" => "pages#contact"
  get "/rlygenerator" => "pages#generator"
  get "/orlygenerator" => "pages#generator"
  get "/rlyslack" => "pages#generator"
  get "/rlyweb" => "pages#rlyweb"
  get "/rly" => "pages#rlyweb"
  get "/code-of-conduct" => "pages#code_of_conduct"
  get "/report-abuse" => "pages#report_abuse"
  get "/faq" => "pages#faq"
  get "/live" => "pages#live"
  get "/swagnets" => "pages#swagnets"
  get "/welcome" => "pages#welcome"
  get "/challenge" => "pages#challenge"
  get "/badge" => "pages#badge"
  get "/💸", to: redirect("t/hiring")
  get "/security", to: "pages#bounty"
  get "/survey", to: redirect("https://dev.to/ben/final-thoughts-on-the-state-of-the-web-survey-44nn")
  get "/now" => "pages#now"
  get "/events" => "events#index"
  get "/workshops", to: redirect("events")
  get "/sponsorship-info" => "pages#sponsorship_faq"
  get "/sponsors" => "pages#sponsors"
  get "/search" => "stories#search"
  post "articles/preview" => "articles#preview"
  post "comments/preview" => "comments#preview"
  get "/stories/warm_comments/:username/:slug" => "stories#warm_comments"
  get "/shop", to: redirect("https://shop.dev.to/")
  get "/mod" => "moderations#index", :as => :mod
  get "/mod/:tag" => "moderations#index"
  get "/page/crayons" => "pages#crayons"

  post "/fallback_activity_recorder" => "ga_events#create"

  get "/page/:slug" => "pages#show"

  scope "p" do
    pages_actions = %w[rly rlyweb welcome twitter_moniter editor_guide publishing_from_rss_guide information
                       markdown_basics scholarships wall_of_patrons badges]
    pages_actions.each do |action|
      get action, action: action, controller: "pages"
    end
  end

  get "/settings/(:tab)" => "users#edit", :as => :user_settings
  get "/settings/:tab/:org_id" => "users#edit", :constraints => { tab: /organization/ }
  get "/settings/:tab/:id" => "users#edit", :constraints => { tab: /response-templates/ }
  get "/signout_confirm" => "users#signout_confirm"
  get "/dashboard" => "dashboards#show"
  get "/dashboard/pro" => "dashboards#pro"
  get "dashboard/pro/org/:org_id" => "dashboards#pro"
  get "dashboard/following" => "dashboards#following_tags"
  get "dashboard/following_tags" => "dashboards#following_tags"
  get "dashboard/following_users" => "dashboards#following_users"
  get "dashboard/following_organizations" => "dashboards#following_organizations"
  get "dashboard/following_podcasts" => "dashboards#following_podcasts"
  get "/dashboard/:which" => "dashboards#followers", :constraints => { which: /user_followers/ }
  get "/dashboard/:which/:org_id" => "dashboards#show",
      :constraints => {
        which: /organization/
      }
  get "/dashboard/:username" => "dashboards#show"

  # for testing rails mailers
  unless Rails.env.production?
    get "/rails/mailers" => "rails/mailers#index"
    get "/rails/mailers/*path" => "rails/mailers#preview"
  end

  get "/embed/:embeddable" => "liquid_embeds#show"

  # serviceworkers
  get "/serviceworker" => "service_worker#index"
  get "/manifest" => "service_worker#manifest"

  get "/shell_top" => "shell#top"
  get "/shell_bottom" => "shell#bottom"

  get "/new" => "articles#new"
  get "/new/:template" => "articles#new"

  get "/pod", to: "podcast_episodes#index"
  get "/podcasts", to: redirect("pod")
  get "/readinglist" => "reading_list_items#index"
  get "/readinglist/:view" => "reading_list_items#index", :constraints => { view: /archive/ }

  get "/feed" => "articles#feed", :as => "feed", :defaults => { format: "rss" }
  get "/feed/tag/:tag" => "articles#feed",
      :as => "tag_feed", :defaults => { format: "rss" }
  get "/feed/:username" => "articles#feed",
      :as => "user_feed", :defaults => { format: "rss" }
  get "/rss" => "articles#feed", :defaults => { format: "rss" }

  get "/tag/:tag" => "stories#index"
  get "/t/:tag", to: "stories#index", as: :tag
  get "/t/:tag/edit", to: "tags#edit"
  get "/t/:tag/admin", to: "tags#admin"
  patch "/tag/:id", to: "tags#update"
  get "/t/:tag/top/:timeframe" => "stories#index"
  get "/t/:tag/page/:page" => "stories#index"
  get "/t/:tag/:timeframe" => "stories#index",
      :constraints => { timeframe: /latest/ }

  get "/badge/:slug" => "badges#show"

  get "/top/:timeframe" => "stories#index"

  get "/:timeframe" => "stories#index", :constraints => { timeframe: /latest/ }

  # Legacy comment format (might still be floating around app, and external links)
  get "/:username/:slug/comments" => "comments#index"
  get "/:username/:slug/comments/:id_code" => "comments#index"
  get "/:username/:slug/comments/:id_code/edit" => "comments#edit"
  get "/:username/:slug/comments/:id_code/delete_confirm" => "comments#delete_confirm"

  # Proper link format
  get "/:username/comment/:id_code" => "comments#index"
  get "/:username/comment/:id_code/edit" => "comments#edit"
  get "/:username/comment/:id_code/delete_confirm" => "comments#delete_confirm"
  get "/:username/comment/:id_code/mod" => "moderations#comment"
  get "/:username/comment/:id_code/settings", to: "comments#settings"

  get "/:username/:slug/:view" => "stories#show",
      :constraints => { view: /moderate/ }
  get "/:username/:slug/mod" => "moderations#article"
  get "/:username/:slug/manage" => "articles#manage"
  get "/:username/:slug/edit" => "articles#edit"
  get "/:username/:slug/delete_confirm" => "articles#delete_confirm"
  get "/:username/:slug/stats" => "articles#stats"
  get "/:username/:view" => "stories#index",
      :constraints => { view: /comments|moderate|admin/ }
  get "/:username/:slug" => "stories#show"
  get "/:sitemap" => "sitemaps#show",
      :constraints => { format: /xml/, sitemap: /sitemap\-.+/ }
  get "/:username" => "stories#index"

  root "stories#index"
end

# rubocop:enable Metrics/BlockLength
