# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  use_doorkeeper do
    controllers tokens: "oauth/tokens"
  end

  # Devise does not support scoping omniauth callbacks under a dynamic segment
  # so this lives outside our i18n scope.
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    registrations: "registrations",
    invitations: "invitations",
    passwords: "passwords",
    confirmations: "confirmations"
  }

  devise_scope :user do
    get "/enter", to: "registrations#new", as: :sign_up
    get "/confirm-email", to: "confirmations#new"
    delete "/sign_out", to: "devise/sessions#destroy"
  end

  get "/r/mobile", to: "deep_links#mobile"
  get "/.well-known/apple-app-site-association", to: "deep_links#aasa"

  # [@forem/delightful] - all routes are nested under this optional scope to
  # begin supporting i18n.
  scope "(/locale/:locale)", defaults: { locale: nil } do
    get "/locale/:locale", to: "stories#index"
    require "sidekiq/web"
    require "sidekiq_unique_jobs/web"
    require "sidekiq/cron/web"

    authenticated :user, ->(user) { user.tech_admin? } do
      Sidekiq::Web.class_eval do
        use Rack::Protection, permitted_origins: [URL.url] # resolve Rack Protection HttpOrigin
      end
      mount Sidekiq::Web => "/sidekiq"
      mount FieldTest::Engine, at: "abtests"
    end

    namespace :admin do
      get "/", to: "overview#index"

      # NOTE: [@ridhwana] These are the admin routes that have stayed the same even with the
      # restructure. They'll move into routes/admin.rb once we remove the old code.
      authenticate :user, ->(user) { user.tech_admin? } do
        mount Blazer::Engine, at: "blazer"

        flipper_ui = Flipper::UI.app(Flipper,
                                     { rack_protection: { except: %i[authenticity_token form_token json_csrf
                                                                     remote_token http_origin session_hijacking] } })
        mount flipper_ui, at: "feature_flags"
      end
      resources :invitations, only: %i[index new create destroy]
      resources :organization_memberships, only: %i[update destroy create]
      resources :permissions, only: %i[index]
      resources :reactions, only: [:update]
      resources :consumer_apps, only: %i[index new create edit update destroy]
      namespace :settings do
        resources :authentications, only: [:create]
        resources :campaigns, only: [:create]
        resources :mascots, only: [:create]
        resources :rate_limits, only: [:create]
      end
      namespace :users do
        resources :gdpr_delete_requests, only: %i[index destroy]
      end
      resources :users, only: %i[index show edit update destroy] do
        resources :email_messages, only: :show
        member do
          post "banish"
          post "export_data"
          post "full_delete"
          patch "user_status"
          post "merge"
          delete "remove_identity"
          post "send_email"
          post "verify_email_ownership"
          patch "unlock_access"
        end
      end

      # These redirects serve as a safeguard to prevent 404s for any Admins
      # who have the old badge_achievement URLs bookmarked.
      get "/badges/badge_achievements", to: redirect("/admin/badge_achievements")
      get "/badges/badge_achievements/award_badges", to: redirect("/admin/badge_achievements/award_badges")

      # NOTE: [@ridhwana] All these conditional statements are temporary conditions.
      # We check that the database table exists to avoid the DB setup failing
      # because the code relies on the presence of a table.
      if Database.table_available?("flipper_features")
        # NOTE: [@ridhwana] admin_routes will require the rails app to be reloaded when the feature flag is toggled
        # You can find more details on why we had to implement it this way in this PR
        # https://github.com/forem/forem/pull/13114
        admin_routes = FeatureFlag.enabled?(:admin_restructure) ? :admin : :current_admin
        draw admin_routes
      end
    end

    namespace :stories, defaults: { format: "json" } do
      resource :feed, only: [:show] do
        get ":timeframe", to: "feeds#show"
      end
    end

    namespace :api, defaults: { format: "json" } do
      scope module: :v0,
            constraints: ApiConstraints.new(version: 0, default: true) do
        resources :articles, only: %i[index show create update] do
          collection do
            get "me(/:status)", to: "articles#me", as: :me, constraints: { status: /published|unpublished|all/ }
            get "/:username/:slug", to: "articles#show_by_slug", as: :slug
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
        resources :webhooks, only: %i[index create show destroy]

        resources :listings, only: %i[index show create update]
        get "/listings/category/:category", to: "listings#index", as: :listings_category
        get "/analytics/totals", to: "analytics#totals"
        get "/analytics/historical", to: "analytics#historical"
        get "/analytics/past_day", to: "analytics#past_day"
        get "/analytics/referrers", to: "analytics#referrers"

        resources :health_checks, only: [] do
          collection do
            get :app
            get :search
            get :database
            get :cache
          end
        end

        resources :profile_images, only: %i[show], param: :username
        resources :organizations, only: [:show], param: :username do
          resources :users, only: [:index], to: "organizations#users"
          resources :listings, only: [:index], to: "organizations#listings"
          resources :articles, only: [:index], to: "organizations#articles"
        end

        namespace :admin do
          resource :config, only: %i[show update], defaults: { format: :json }
        end
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
    resources :chat_channel_memberships, only: %i[index create edit update destroy]
    resources :articles, only: %i[update create destroy] do
      patch "/admin_unpublish", to: "articles#admin_unpublish"
    end
    resources :article_mutes, only: %i[update]
    resources :comments, only: %i[create update destroy] do
      patch "/hide", to: "comments#hide"
      patch "/unhide", to: "comments#unhide"
      patch "/admin_delete", to: "comments#admin_delete"
      collection do
        post "/moderator_create", to: "comments#moderator_create"
      end
    end
    resources :comment_mutes, only: %i[update]
    resources :users, only: %i[index], defaults: { format: :json } do # internal API
      constraints(-> { FeatureFlag.enabled?(:mobile_notifications) }) do
        collection do
          resources :devices, only: %i[create destroy]
        end
      end
    end
    resources :users, only: %i[update]
    resources :reactions, only: %i[index create]
    resources :response_templates, only: %i[index create edit update destroy]
    resources :feedback_messages, only: %i[index create]
    resources :organizations, only: %i[update create destroy]
    resources :followed_articles, only: [:index]
    resources :follows, only: %i[show create] do
      collection do
        get "/bulk_show", to: "follows#bulk_show"
        patch "/bulk_update", to: "follows#bulk_update"
      end
    end
    resources :image_uploads, only: [:create]
    resources :notifications, only: [:index]
    resources :tags, only: [:index] do
      collection do
        get "/onboarding", to: "tags#onboarding"
      end
    end
    resources :stripe_active_cards, only: %i[create update destroy]
    resources :github_repos, only: %i[index] do
      collection do
        post "/update_or_create", to: "github_repos#update_or_create"
      end
    end
    resources :events, only: %i[index show]
    resources :videos, only: %i[index create new]
    resources :video_states, only: [:create]
    resources :twilio_tokens, only: [:show]
    resources :html_variant_trials, only: [:create]
    resources :html_variant_successes, only: [:create]
    resources :tag_adjustments, only: %i[create destroy]
    resources :rating_votes, only: [:create]
    resources :page_views, only: %i[create update]
    resources :listings, only: %i[index new create edit update destroy dashboard]
    resources :credits, only: %i[index new create] do
      get "purchase", on: :collection, to: "credits#new"
    end
    resources :reading_list_items, only: [:update]
    resources :poll_votes, only: %i[show create]
    resources :poll_skips, only: [:create]
    resources :profile_pins, only: %i[create update]
    resources :display_ad_events, only: [:create]
    resources :badges, only: [:index]
    resources :user_blocks, param: :blocked_id, only: %i[show create destroy]
    resources :podcasts, only: %i[new create]
    resources :article_approvals, only: %i[create]
    resources :video_chats, only: %i[show]
    resources :sidebars, only: %i[show]
    resources :user_subscriptions, only: %i[create] do
      collection do
        get "/subscribed", action: "subscribed"
      end
    end
    namespace :followings, defaults: { format: :json } do
      get :users
      get :tags
      get :organizations
      get :podcasts
    end

    resource :onboarding, only: :show
    resources :profiles, only: %i[update]
    resources :profile_field_groups, only: %i[index], defaults: { format: :json }

    resources :liquid_tags, only: %i[index], defaults: { format: :json }

    get "/verify_email_ownership", to: "email_authorizations#verify", as: :verify_email_authorizations
    get "/search/tags", to: "search#tags"
    get "/search/chat_channels", to: "search#chat_channels"
    get "/search/listings", to: "search#listings"
    get "/search/users", to: "search#users"
    get "/search/usernames", to: "search#usernames"
    get "/search/feed_content", to: "search#feed_content"
    get "/search/reactions", to: "search#reactions"
    get "/chat_channel_memberships/find_by_chat_channel_id", to: "chat_channel_memberships#find_by_chat_channel_id"
    get "/listings/dashboard", to: "listings#dashboard"
    get "/listings/:category", to: "listings#index", as: :listing_category
    get "/listings/:category/:slug", to: "listings#index", as: :listing_slug
    get "/listings/:category/:slug/:view", to: "listings#index",
                                           constraints: { view: /moderate/ }
    get "/listings/:category/:slug/delete_confirm", to: "listings#delete_confirm"
    delete "/listings/:category/:slug", to: "listings#destroy"
    get "/notifications/:filter", to: "notifications#index"
    get "/notifications/:filter/:org_id", to: "notifications#index"
    get "/notification_subscriptions/:notifiable_type/:notifiable_id", to: "notification_subscriptions#show"
    post "/notification_subscriptions/:notifiable_type/:notifiable_id", to: "notification_subscriptions#upsert"
    patch "/onboarding_update", to: "users#onboarding_update"
    patch "/onboarding_checkbox_update", to: "users#onboarding_checkbox_update"
    get "email_subscriptions/unsubscribe"
    post "/chat_channels/:id/moderate", to: "chat_channels#moderate"
    post "/chat_channels/:id/open", to: "chat_channels#open"
    get "/connect", to: "chat_channels#index"
    get "/connect/:slug", to: "chat_channels#index"
    get "/chat_channels/:id/channel_info", to: "chat_channels#channel_info", as: :chat_channel_info
    post "/chat_channels/create_chat", to: "chat_channels#create_chat"
    post "/chat_channels/block_chat", to: "chat_channels#block_chat"
    post "/chat_channel_memberships/remove_membership", to: "chat_channel_memberships#remove_membership"
    post "/chat_channel_memberships/add_membership", to: "chat_channel_memberships#add_membership"
    post "/join_chat_channel", to: "chat_channel_memberships#join_channel"
    delete "/messages/:id", to: "messages#destroy"
    patch "/messages/:id", to: "messages#update"
    get "/internal", to: redirect("/admin")
    get "/internal/:path", to: redirect("/admin/%{path}")

    post "/pusher/auth", to: "pusher#auth"

    # Chat channel
    patch "/chat_channels/update_channel/:id", to: "chat_channels#update_channel"
    post "/create_channel", to: "chat_channels#create_channel"

    # Chat Channel Membership json response
    get "/chat_channel_memberships/chat_channel_info/:id", to: "chat_channel_memberships#chat_channel_info"
    post "/chat_channel_memberships/create_membership_request", to: "chat_channel_memberships#create_membership_request"
    patch "/chat_channel_memberships/leave_membership/:id", to: "chat_channel_memberships#leave_membership"
    patch "/chat_channel_memberships/update_membership/:id", to: "chat_channel_memberships#update_membership"
    get "/channel_request_info/", to: "chat_channel_memberships#request_details"
    patch "/chat_channel_memberships/update_membership_role/:id", to: "chat_channel_memberships#update_membership_role"
    get "/join_channel_invitation/:channel_slug", to: "chat_channel_memberships#join_channel_invitation"
    post "/joining_invitation_response", to: "chat_channel_memberships#joining_invitation_response"

    get "/social_previews/article/:id", to: "social_previews#article", as: :article_social_preview
    get "/social_previews/user/:id", to: "social_previews#user", as: :user_social_preview
    get "/social_previews/organization/:id", to: "social_previews#organization", as: :organization_social_preview
    get "/social_previews/tag/:id", to: "social_previews#tag", as: :tag_social_preview
    get "/social_previews/listing/:id", to: "social_previews#listing", as: :listing_social_preview
    get "/social_previews/comment/:id", to: "social_previews#comment", as: :comment_social_preview

    get "/async_info/base_data", controller: "async_info#base_data", defaults: { format: :json }
    get "/async_info/shell_version", controller: "async_info#shell_version", defaults: { format: :json }

    # Settings
    post "users/join_org", to: "users#join_org"
    post "users/leave_org/:organization_id", to: "users#leave_org", as: :users_leave_org
    post "users/add_org_admin", to: "users#add_org_admin"
    post "users/remove_org_admin", to: "users#remove_org_admin"
    post "users/remove_from_org", to: "users#remove_from_org"
    delete "users/remove_identity", to: "users#remove_identity"
    post "users/request_destroy", to: "users#request_destroy", as: :user_request_destroy
    get "users/confirm_destroy/:token", to: "users#confirm_destroy", as: :user_confirm_destroy
    delete "users/full_delete", to: "users#full_delete", as: :user_full_delete
    post "organizations/generate_new_secret", to: "organizations#generate_new_secret"
    post "users/api_secrets", to: "api_secrets#create", as: :users_api_secrets
    delete "users/api_secrets/:id", to: "api_secrets#destroy", as: :users_api_secret
    post "users/update_password", to: "users#update_password", as: :user_update_password

    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".

    # You can have the root of your site routed with "root
    get "/robots.:format", to: "pages#robots"
    get "/api", to: redirect("https://docs.forem.com/api")
    get "/privacy", to: "pages#privacy"
    get "/terms", to: "pages#terms"
    get "/contact", to: "pages#contact"
    get "/code-of-conduct", to: "pages#code_of_conduct"
    get "/report-abuse", to: "pages#report_abuse"
    get "/welcome", to: "pages#welcome"
    get "/challenge", to: "pages#challenge"
    get "/checkin", to: "pages#checkin"
    get "/badge", to: "pages#badge", as: :pages_badge
    get "/💸", to: redirect("t/hiring")
    get "/survey", to: redirect("https://dev.to/ben/final-thoughts-on-the-state-of-the-web-survey-44nn")
    get "/events", to: "events#index"
    get "/workshops", to: redirect("events")
    get "/sponsors", to: "pages#sponsors"
    get "/search", to: "stories#search"
    post "articles/preview", to: "articles#preview"
    post "comments/preview", to: "comments#preview"

    # These routes are required by links in the sites and will most likely to be replaced by a db page
    get "/about", to: "pages#about"
    get "/about-listings", to: "pages#about_listings"
    get "/security", to: "pages#bounty"
    get "/community-moderation", to: "pages#community_moderation"
    get "/faq", to: "pages#faq"
    get "/page/post-a-job", to: "pages#post_a_job"
    get "/tag-moderation", to: "pages#tag_moderation"

    # NOTE: can't remove the hardcoded URL here as SiteConfig is not available here, we should eventually
    # setup dynamic redirects, see <https://github.com/thepracticaldev/dev.to/issues/7267>
    get "/shop", to: redirect("https://shop.dev.to")

    get "/mod", to: "moderations#index", as: :mod
    get "/mod/:tag", to: "moderations#index"

    post "/fallback_activity_recorder", to: "ga_events#create"

    get "/page/:slug", to: "pages#show"

    # TODO: [forem/teamsmash] removed the /p/information view and added a redirect for SEO purposes.
    # We need to remove this route in 2 months (11 January 2021).
    get "/p/information", to: redirect("/about")

    scope "p" do
      pages_actions = %w[welcome editor_guide publishing_from_rss_guide markdown_basics badges].freeze
      pages_actions.each do |action|
        get action, action: action, controller: "pages"
      end
    end

    # Redirect previous settings changed after https://github.com/forem/forem/pull/11347
    get "/settings/integrations", to: redirect("/settings/extensions")
    get "/settings/misc", to: redirect("/settings")
    get "/settings/publishing-from-rss", to: redirect("/settings/extensions")
    get "/settings/ux", to: redirect("/settings/customization")

    get "/settings/(:tab)", to: "users#edit", as: :user_settings
    get "/settings/:tab/:org_id", to: "users#edit", constraints: { tab: /organization/ }
    get "/settings/:tab/:id", to: "users#edit", constraints: { tab: /response-templates/ }
    get "/signout_confirm", to: "users#signout_confirm"
    get "/dashboard", to: "dashboards#show"
    get "/dashboard/analytics", to: "dashboards#analytics"
    get "dashboard/analytics/org/:org_id", to: "dashboards#analytics", as: :dashboard_analytics_org
    get "dashboard/following", to: "dashboards#following_tags"
    get "dashboard/following_tags", to: "dashboards#following_tags"
    get "dashboard/following_users", to: "dashboards#following_users"
    get "dashboard/following_organizations", to: "dashboards#following_organizations"
    get "dashboard/following_podcasts", to: "dashboards#following_podcasts"
    get "/dashboard/subscriptions", to: "dashboards#subscriptions"
    get "/dashboard/:which", to: "dashboards#followers", constraints: { which: /user_followers/ }
    get "/dashboard/:which/:org_id", to: "dashboards#show",
                                     constraints: {
                                       which: /organization/
                                     }
    get "/dashboard/:username", to: "dashboards#show"

    # for testing rails mailers
    unless Rails.env.production?
      get "/rails/mailers", to: "rails/mailers#index"
      get "/rails/mailers/*path", to: "rails/mailers#preview"
    end

    get "/embed/:embeddable", to: "liquid_embeds#show", as: "liquid_embed"

    # serviceworkers
    get "/serviceworker", to: "service_worker#index"
    get "/manifest", to: "service_worker#manifest"

    # open search
    get "/open-search", to: "open_search#show",
                        constraints: { format: /xml/ }

    get "/new", to: "articles#new"
    get "/new/:template", to: "articles#new"

    get "/pod", to: "podcast_episodes#index"
    get "/podcasts", to: redirect("pod")
    get "/readinglist", to: "reading_list_items#index"
    get "/readinglist/:view", to: "reading_list_items#index", constraints: { view: /archive/ }

    get "/feed", to: "articles#feed", as: "feed", defaults: { format: "rss" }
    get "/feed/tag/:tag", to: "articles#feed", as: "tag_feed", defaults: { format: "rss" }
    get "/feed/latest", to: "articles#feed", as: "latest_feed", defaults: { format: "rss" }
    get "/feed/:username", to: "articles#feed", as: "user_feed", defaults: { format: "rss" }
    get "/rss", to: "articles#feed", defaults: { format: "rss" }

    get "/tag/:tag", to: "stories#index"
    get "/t/:tag", to: "stories#index", as: :tag
    get "/t/:tag/edit", to: "tags#edit"
    get "/t/:tag/admin", to: "tags#admin"
    patch "/tag/:id", to: "tags#update"
    get "/t/:tag/top/:timeframe", to: "stories#index"
    get "/t/:tag/page/:page", to: "stories#index"
    get "/t/:tag/:timeframe", to: "stories#index",
                              constraints: { timeframe: /latest/ }

    get "/badge/:slug", to: "badges#show", as: :badge

    get "/top/:timeframe", to: "stories#index"

    get "/:timeframe", to: "stories#index", constraints: { timeframe: /latest/ }

    get "/:username/series", to: "collections#index", as: "user_series"
    get "/:username/series/:id", to: "collections#show"

    # Legacy comment format (might still be floating around app, and external links)
    get "/:username/:slug/comments", to: "comments#index"
    get "/:username/:slug/comments/:id_code", to: "comments#index"
    get "/:username/:slug/comments/:id_code/edit", to: "comments#edit"
    get "/:username/:slug/comments/:id_code/delete_confirm", to: "comments#delete_confirm"

    # Proper link format
    get "/:username/comment/:id_code", to: "comments#index"
    get "/:username/comment/:id_code/edit", to: "comments#edit"
    get "/:username/comment/:id_code/delete_confirm", to: "comments#delete_confirm"
    get "/:username/comment/:id_code/mod", to: "moderations#comment"
    get "/:username/comment/:id_code/settings", to: "comments#settings"

    get "/:username/:slug/:view", to: "stories#show",
                                  constraints: { view: /moderate/ }
    get "/:username/:slug/mod", to: "moderations#article"
    get "/:username/:slug/actions_panel", to: "moderations#actions_panel"
    get "/:username/:slug/manage", to: "articles#manage"
    get "/:username/:slug/edit", to: "articles#edit"
    get "/:username/:slug/delete_confirm", to: "articles#delete_confirm"
    get "/:username/:slug/stats", to: "articles#stats"
    get "/:username/:view", to: "stories#index",
                            constraints: { view: /comments|moderate|admin/ }
    get "/:username/:slug", to: "stories#show"
    get "/:sitemap", to: "sitemaps#show",
                     constraints: { format: /xml/, sitemap: /sitemap-.+/ }
    get "/:username", to: "stories#index", as: "user_profile"

    root "stories#index"
  end
end

# rubocop:enable Metrics/BlockLength
