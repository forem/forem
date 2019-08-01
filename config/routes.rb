# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    session: "sessions",
    registrations: "registrations"
  }

  authenticated :user, ->(user) { user.tech_admin? } do
    mount DelayedJobWeb, at: "/delayed_job"
  end

  devise_scope :user do
    delete "/sign_out" => "devise/sessions#destroy"
    get "/enter" => "registrations#new", as: :sign_up
  end

  namespace :admin do
    # Check administrate gem docs
    DashboardManifest::DASHBOARDS.each do |dashboard_resource|
      resources dashboard_resource
    end

    root controller: DashboardManifest::ROOT_DASHBOARD, action: :index
  end

  namespace :internal do
    resources :articles, only: %i[index show update]
    resources :broadcasts, only: %i[index new create edit update]
    resources :buffer_updates, only: %i[create update]
    resources :classified_listings, only: %i[index edit update destroy]
    resources :comments, only: [:index]
    resources :dogfood, only: [:index]
    resources :events, only: %i[index create update]
    resources :feedback_messages, only: %i[index show]
    resources :listings, only: %i[index edit update destroy], controller: "classified_listings"
    resources :pages, only: %i[index new create edit update destroy]
    resources :podcasts, only: %i[index edit update destroy] do
      member do
        post :add_admin
        delete :remove_admin
      end
    end
    resources :reactions, only: [:update]
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
      end
    end
    resources :organization_memberships, only: %i[update destroy create]
    resources :welcome, only: %i[index create]
    resources :tools, only: %i[index create] do
      collection do
        post "bust_cache"
      end
    end
  end

  namespace :api, defaults: { format: "json" } do
    scope module: :v0,
          constraints: ApiConstraints.new(version: 0, default: true) do
      resources :articles, only: %i[index show create update] do
        collection do
          get "/onboarding", to: "articles#onboarding"
        end
      end
      resources :comments, only: %i[index show]
      resources :chat_channels, only: [:show]
      resources :videos, only: [:index]
      resources :podcast_episodes, only: [:index]
      resources :reactions, only: [:create] do
        collection do
          post "/onboarding", to: "reactions#onboarding"
        end
      end
      resources :users, only: %i[index show]
      resources :tags, only: [:index] do
        collection do
          get "/onboarding", to: "tags#onboarding"
        end
      end
      resources :follows, only: [:create]
      resources :github_repos, only: [:index] do
        collection do
          post "/update_or_create", to: "github_repos#update_or_create"
        end
      end

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

  resources :messages, only: [:create]
  resources :chat_channels, only: %i[index show create update]
  resources :chat_channel_memberships, only: %i[create update destroy]
  resources :articles, only: %i[update create destroy]
  resources :article_mutes, only: %i[update]
  resources :comments, only: %i[create update destroy]
  resources :comment_mutes, only: %i[update]
  resources :users, only: [:update] do
    resource :twitch_stream_updates, only: %i[show create]
  end
  resources :twitch_live_streams, only: :show, param: :username
  resources :reactions, only: %i[index create]
  resources :feedback_messages, only: %i[index create]
  resources :organizations, only: %i[update create]
  resources :followed_articles, only: [:index]
  resources :follows, only: %i[show create update]
  resources :giveaways, only: %i[new edit update]
  resources :image_uploads, only: [:create]
  resources :blocks
  resources :notifications, only: [:index]
  resources :tags, only: [:index]
  resources :stripe_active_cards, only: %i[create update destroy]
  resources :live_articles, only: [:index]
  resources :github_repos, only: %i[create update]
  resources :buffered_articles, only: [:index]
  resources :events, only: %i[index show]
  resources :additional_content_boxes, only: [:index]
  resources :videos, only: %i[index create new]
  resources :video_states, only: [:create]
  resources :twilio_tokens, only: [:show]
  resources :html_variants, only: %i[index new create show edit update]
  resources :html_variant_trials, only: [:create]
  resources :html_variant_successes, only: [:create]
  resources :push_notification_subscriptions, only: [:create]
  resources :tag_adjustments, only: [:create]
  resources :rating_votes, only: [:create]
  resources :page_views, only: %i[create update]
  resources :classified_listings, path: :listings, only: %i[index new create edit update delete dashboard]
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

  get "/chat_channel_memberships/find_by_chat_channel_id" => "chat_channel_memberships#find_by_chat_channel_id"
  get "/listings/dashboard" => "classified_listings#dashboard"
  get "/listings/:category" => "classified_listings#index"
  get "/listings/:category/:slug" => "classified_listings#index", as: :classified_listing_slug
  get "/listings/:category/:slug/:view" => "classified_listings#index",
      constraints: { view: /moderate/ }
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
  post "/chat_channels/create_chat" => "chat_channels#create_chat"
  post "/chat_channels/block_chat" => "chat_channels#block_chat"
  get "/live/:username" => "twitch_live_streams#show"
  get "/pro" => "pro_accounts#index"

  post "/pusher/auth" => "pusher#auth"

  get "/social_previews/article/:id" => "social_previews#article", as: :article_social_preview
  get "/social_previews/user/:id" => "social_previews#user", as: :user_social_preview
  get "/social_previews/organization/:id" => "social_previews#organization", as: :organization_social_preview
  get "/social_previews/tag/:id" => "social_previews#tag", as: :tag_social_preview
  get "/social_previews/listing/:id" => "social_previews#listing", as: :listing_social_preview

  get "/async_info/base_data", controller: "async_info#base_data", defaults: { format: :json }

  get "/hello-goodbye-to-the-go-go-go",
      to: redirect("ben/hello-goodbye-to-the-go-go-go")
  get "/dhh-on-the-future-of-rails",
      to: redirect("ben/dhh-on-the-future-of-rails")
  get "/christopher-chedeau-on-the-philosophies-of-react",
      to: redirect("ben/christopher-chedeau-on-the-philosophies-of-react")
  get "/javascript-fatigue-buzzword",
      to: redirect("ben/javascript-fatigue-buzzword")
  get "/chris-seaton-making-ruby-fast",
      to: redirect("ben/chris-seaton-making-ruby-fast")
  get "/communicating-intent-the-perpetually-misunderstood-ruby-bang",
      to: redirect("tom/communicating-intent-the-perpetually-misunderstood-ruby-bang")
  get "/quick-tip-grepping-rails-routes",
      to: redirect("tom/quick-tip-grepping-rails-routes")
  get "/use-cases-for-githubs-new-direct-upload-feature",
      to: redirect("ben/use-cases-for-githubs-new-direct-upload-feature")
  get "/this-blog-post-was-written-using-draft-js",
      to: redirect("ben/this-blog-post-was-written-using-draft-js")
  get "/the-future-of-software-development",
      to: redirect("ben/the-future-of-software-development")
  get "/the-zen-of-missing-out-on-the-next-great-programming-tool",
      to: redirect("ben/the-zen-of-missing-out-on-the-next-great-programming-tool")
  get "/the-joy-and-benefit-of-being-an-early-adopter-in-programming",
      to: redirect("ben/the-joy-and-benefit-of-being-an-early-adopter-in-programming")
  get "/watkinsmatthewp/every-developer-should-write-a-personal-automation-api",
      to: redirect("anotherdevblog/every-developer-should-write-a-personal-automation-api")

  # Settings
  post "users/update_language_settings" => "users#update_language_settings"
  post "users/update_twitch_username" => "users#update_twitch_username"
  post "users/join_org" => "users#join_org"
  post "users/leave_org/:organization_id" => "users#leave_org"
  post "users/add_org_admin" => "users#add_org_admin"
  post "users/remove_org_admin" => "users#remove_org_admin"
  post "users/remove_from_org" => "users#remove_from_org"
  delete "users/remove_association", to: "users#remove_association"
  delete "users/destroy", to: "users#destroy"
  post "organizations/generate_new_secret" => "organizations#generate_new_secret"
  post "users/api_secrets" => "api_secrets#create", as: :users_api_secrets
  delete "users/api_secrets/:id" => "api_secrets#destroy", as: :users_api_secret

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root
  get "/about" => "pages#about"
  get "/api", to: "pages#api"
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
  get "/onboarding" => "pages#onboarding"
  get "/shecoded" => "pages#shecoded"
  get "/💸", to: redirect("t/hiring")
  get "/security", to: "pages#bounty"
  get "/survey", to: redirect("https://dev.to/ben/final-thoughts-on-the-state-of-the-web-survey-44nn")
  get "/now" => "pages#now"
  get "/events" => "events#index"
  get "/workshops", to: redirect("events")
  get "/sponsorship-info" => "pages#sponsorship_faq"
  get "/organization-info" => "pages#org_info"
  get "/sponsors" => "pages#sponsors"
  get "/search" => "stories#search"
  post "articles/preview" => "articles#preview"
  post "comments/preview" => "comments#preview"
  get "/stories/warm_comments/:username/:slug" => "stories#warm_comments"
  get "/freestickers" => "giveaways#new"
  get "/shop", to: redirect("https://shop.dev.to/")
  get "/mod" => "moderations#index"

  post "/fallback_activity_recorder" => "ga_events#create"

  get "/page/:slug" => "pages#show"

  scope "p" do
    pages_actions = %w[rly rlyweb welcome twitter_moniter editor_guide publishing_from_rss_guide information
                       markdown_basics scholarships wall_of_patrons badges]
    pages_actions.each do |action|
      get action, action: action, controller: "pages"
    end
  end

  get "/settings/(:tab)" => "users#edit"
  get "/settings/:tab/:org_id" => "users#edit"
  get "/signout_confirm" => "users#signout_confirm"
  get "/dashboard" => "dashboards#show"
  get "/dashboard/pro" => "dashboards#pro"
  get "dashboard/pro/org/:org_id" => "dashboards#pro"
  get "dashboard/following" => "dashboards#following"
  get "/dashboard/:which" => "dashboards#followers",
      constraints: {
        which: /organization_user_followers|user_followers/
      }
  get "/dashboard/:which/:org_id" => "dashboards#show",
      constraints: {
        which: /organization/
      }
  get "/dashboard/:username" => "dashboards#show"

  # for testing rails mailers
  unless Rails.env.production?
    get "/rails/mailers" => "rails/mailers#index"
    get "/rails/mailers/*path" => "rails/mailers#preview"
  end

  get "/new" => "articles#new"
  get "/new/:template" => "articles#new"

  get "/pod", to: "podcast_episodes#index"
  get "/podcasts", to: redirect("pod")
  get "/readinglist" => "reading_list_items#index"
  get "/readinglist/:view" => "reading_list_items#index", constraints: { view: /archive/ }
  get "/history", to: "history#index", as: :history

  get "/feed" => "articles#feed", as: "feed", defaults: { format: "rss" }
  get "/feed/tag/:tag" => "articles#feed",
      as: "tag_feed", defaults: { format: "rss" }
  get "/feed/:username" => "articles#feed",
      as: "user_feed", defaults: { format: "rss" }
  get "/rss" => "articles#feed", defaults: { format: "rss" }

  get "/tag/:tag" => "stories#index"
  get "/t/:tag", to: "stories#index", as: :tag
  get "/t/:tag/edit", to: "tags#edit"
  get "/t/:tag/admin", to: "tags#admin"
  patch "/tag/:id", to: "tags#update"
  get "/t/:tag/top/:timeframe" => "stories#index"
  get "/t/:tag/:timeframe" => "stories#index",
      constraints: { timeframe: /latest/ }

  get "/badge/:slug" => "badges#show"

  get "/top/:timeframe" => "stories#index"

  get "/:timeframe" => "stories#index", constraints: { timeframe: /latest/ }

  # Legacy comment format (might still be floating around app, and external links)
  get "/:username/:slug/comments/new/:parent_id_code" => "comments#new"
  get "/:username/:slug/comments/new" => "comments#new"
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
      constraints: { view: /moderate/ }
  get "/:username/:slug/mod" => "moderations#article"
  get "/:username/:slug/manage" => "articles#manage"
  get "/:username/:slug/edit" => "articles#edit"
  get "/:username/:slug/delete_confirm" => "articles#delete_confirm"
  get "/:username/:slug/stats" => "articles#stats"
  get "/:username/:view" => "stories#index",
      constraints: { view: /comments|moderate|admin/ }
  get "/:username/:slug" => "stories#show"
  get "/:username" => "stories#index"

  root "stories#index"
end

# rubocop:enable Metrics/BlockLength
