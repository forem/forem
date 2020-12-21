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
    invitations: "invitations"
  }

  devise_scope :user do
    get "/enter", to: "registrations#new", as: :sign_up
    get "/confirm-email", to: "devise/confirmations#new"
    delete "/sign_out", to: "devise/sessions#destroy"
  end

  # [@forem/delightful] - all routes are nested under this optional scope to
  # begin supporting i18n.
  scope "(/locale/:locale)", defaults: { locale: nil } do
    get "/locale/:locale" => "stories#index"
    require "sidekiq/web"
    require "sidekiq_unique_jobs/web"
    require "sidekiq/cron/web"

    authenticated :user, ->(user) { user.tech_admin? } do
      Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
      Sidekiq::Web.set :sessions, Rails.application.config.session_options
      Sidekiq::Web.class_eval do
        use Rack::Protection, origin_whitelist: [URL.url] # resolve Rack Protection HttpOrigin
      end
      mount Sidekiq::Web => "/sidekiq"
      mount FieldTest::Engine, at: "abtests"
    end

    namespace :admin do
      get "/" => "admin_portals#index"

      authenticate :user, ->(user) { user.tech_admin? } do
        mount Blazer::Engine, at: "blazer"

        flipper_ui = Flipper::UI.app(Flipper,
                                     { rack_protection: { except: %i[authenticity_token form_token json_csrf
                                                                     remote_token http_origin session_hijacking] } })
        mount flipper_ui, at: "feature_flags"
      end

      namespace :users do
        resources :gdpr_delete_requests, only: %i[index destroy]
      end

      resources :articles, only: %i[index show update]
      resources :broadcasts
      resources :buffer_updates, only: %i[create update]
      resources :listings, only: %i[index edit update destroy]
      resources :listing_categories, only: %i[index edit update new create
                                              destroy], path: "listings/categories"

      resources :comments, only: [:index]
      resources :events, only: %i[index create update new edit]
      resources :feedback_messages, only: %i[index show]
      resources :invitations, only: %i[index new create destroy]
      resources :pages, only: %i[index new create edit update destroy]
      resources :mods, only: %i[index update]
      resources :moderator_actions, only: %i[index]
      resources :navigation_links, only: %i[index update create destroy]
      resources :privileged_reactions, only: %i[index]
      resources :permissions, only: %i[index]
      resources :podcasts, only: %i[index edit update destroy] do
        member do
          post :fetch
          post :add_owner
        end
      end

      # NOTE: @citizen428 The next two resources have a temporary constraint
      # while profile generalization is still WIP
      constraints(->(_request) { FeatureFlag.enabled?(:profile_admin) }) do
        resources :profile_field_groups, only: %i[update create destroy]
        resources :profile_fields, only: %i[index update create destroy]
      end
      resources :reactions, only: [:update]
      resources :response_templates, only: %i[index new edit create update destroy]
      resources :chat_channels, only: %i[index create update destroy] do
        member do
          delete :remove_user
        end
      end
      resources :reports, only: %i[index show], controller: "feedback_messages" do
        collection do
          post "send_email"
          post "create_note"
          post "save_status"
        end
      end
      resources :tags, only: %i[index new create update edit] do
        resource :moderator, only: %i[create destroy], module: "tags"
      end
      resources :users, only: %i[index show edit update] do
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
      resources :organization_memberships, only: %i[update destroy create]
      resources :organizations, only: %i[index show] do
        member do
          patch "update_org_credits"
        end
      end
      resources :sponsorships, only: %i[index edit update new create destroy]
      resources :welcome, only: %i[index create]
      resources :growth, only: %i[index]
      resources :tools, only: %i[index create] do
        collection do
          post "bust_cache"
        end
      end
      resources :webhook_endpoints, only: :index
      resource :config
      resources :badges, only: %i[index edit update new create]
      resources :display_ads, only: %i[index edit update new create destroy]

      resources :html_variants, only: %i[index edit update new create show destroy]
      # These redirects serve as a safegaurd to prevent 404s for any Admins
      # who have the old badge_achievement URLs bookmarked.
      get "/badges/badge_achievements", to: redirect("/admin/badge_achievements")
      get "/badges/badge_achievements/award_badges", to: redirect("/admin/badge_achievements/award_badges")
      resources :badge_achievements, only: %i[index destroy]
      get "/badge_achievements/award_badges", to: "badge_achievements#award"
      post "/badge_achievements/award_badges", to: "badge_achievements#award_badges"
      resources :secrets, only: %i[index]
      put "secrets", to: "secrets#update"
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
            get "/:username/:slug", to: "articles#show_by_slug", as: :slug
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
        end

        namespace :admin do
          resource :config, only: %i[show], defaults: { format: :json }
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
    resources :users, only: %i[index], defaults: { format: :json } # internal API
    resources :users, only: %i[update]
    resources :reactions, only: %i[index create]
    resources :response_templates, only: %i[index create edit update destroy]
    resources :feedback_messages, only: %i[index create]
    resources :organizations, only: %i[update create destroy]
    resources :followed_articles, only: [:index]
    resources :follows, only: %i[show create update] do
      collection do
        get "/bulk_show", to: "follows#bulk_show"
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
    resources :buffer_updates, only: [:create]
    resources :reading_list_items, only: [:update]
    resources :poll_votes, only: %i[show create]
    resources :poll_skips, only: [:create]
    resources :profile_pins, only: %i[create update]
    resources :partnerships, only: %i[index create show], param: :option
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
    get "/search/tags" => "search#tags"
    get "/search/chat_channels" => "search#chat_channels"
    get "/search/listings" => "search#listings"
    get "/search/users" => "search#users"
    get "/search/usernames" => "search#usernames"
    get "/search/feed_content" => "search#feed_content"
    get "/search/reactions" => "search#reactions"
    get "/chat_channel_memberships/find_by_chat_channel_id" => "chat_channel_memberships#find_by_chat_channel_id"
    get "/listings/dashboard" => "listings#dashboard"
    get "/listings/:category" => "listings#index", :as => :listing_category
    get "/listings/:category/:slug" => "listings#index", :as => :listing_slug
    get "/listings/:category/:slug/:view" => "listings#index",
        :constraints => { view: /moderate/ }
    get "/listings/:category/:slug/delete_confirm" => "listings#delete_confirm"
    delete "/listings/:category/:slug" => "listings#destroy"
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
    post "/chat_channel_memberships/remove_membership" => "chat_channel_memberships#remove_membership"
    post "/chat_channel_memberships/add_membership" => "chat_channel_memberships#add_membership"
    post "/join_chat_channel" => "chat_channel_memberships#join_channel"
    delete "/messages/:id" => "messages#destroy"
    patch "/messages/:id" => "messages#update"
    get "/internal", to: redirect("/admin")
    get "/internal/:path", to: redirect("/admin/%{path}")

    post "/pusher/auth" => "pusher#auth"

    # Chat channel
    patch "/chat_channels/update_channel/:id" => "chat_channels#update_channel"
    post "/create_channel" => "chat_channels#create_channel"

    # Chat Channel Membership json response
    get "/chat_channel_memberships/chat_channel_info/:id" => "chat_channel_memberships#chat_channel_info"
    post "/chat_channel_memberships/create_membership_request" => "chat_channel_memberships#create_membership_request"
    patch "/chat_channel_memberships/leave_membership/:id" => "chat_channel_memberships#leave_membership"
    patch "/chat_channel_memberships/update_membership/:id" => "chat_channel_memberships#update_membership"
    get "/channel_request_info/" => "chat_channel_memberships#request_details"
    patch "/chat_channel_memberships/update_membership_role/:id" => "chat_channel_memberships#update_membership_role"
    get "/join_channel_invitation/:channel_slug" => "chat_channel_memberships#join_channel_invitation"
    post "/joining_invitation_response" => "chat_channel_memberships#joining_invitation_response"

    get "/social_previews/article/:id" => "social_previews#article", :as => :article_social_preview
    get "/social_previews/user/:id" => "social_previews#user", :as => :user_social_preview
    get "/social_previews/organization/:id" => "social_previews#organization", :as => :organization_social_preview
    get "/social_previews/tag/:id" => "social_previews#tag", :as => :tag_social_preview
    get "/social_previews/listing/:id" => "social_previews#listing", :as => :listing_social_preview
    get "/social_previews/comment/:id" => "social_previews#comment", :as => :comment_social_preview

    get "/async_info/base_data", controller: "async_info#base_data", defaults: { format: :json }
    get "/async_info/shell_version", controller: "async_info#shell_version", defaults: { format: :json }

    # Settings
    post "users/join_org" => "users#join_org"
    post "users/leave_org/:organization_id" => "users#leave_org", :as => :users_leave_org
    post "users/add_org_admin" => "users#add_org_admin"
    post "users/remove_org_admin" => "users#remove_org_admin"
    post "users/remove_from_org" => "users#remove_from_org"
    delete "users/remove_identity", to: "users#remove_identity"
    post "users/request_destroy", to: "users#request_destroy", as: :user_request_destroy
    get "users/confirm_destroy/:token", to: "users#confirm_destroy", as: :user_confirm_destroy
    delete "users/full_delete", to: "users#full_delete", as: :user_full_delete
    post "organizations/generate_new_secret" => "organizations#generate_new_secret"
    post "users/api_secrets" => "api_secrets#create", :as => :users_api_secrets
    delete "users/api_secrets/:id" => "api_secrets#destroy", :as => :users_api_secret

    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".

    # You can have the root of your site routed with "root
    get "/robots.:format" => "pages#robots"
    get "/api", to: redirect("https://docs.forem.com/api")
    get "/privacy" => "pages#privacy"
    get "/terms" => "pages#terms"
    get "/contact" => "pages#contact"
    get "/code-of-conduct" => "pages#code_of_conduct"
    get "/report-abuse" => "pages#report_abuse"
    get "/welcome" => "pages#welcome"
    get "/challenge" => "pages#challenge"
    get "/checkin" => "pages#checkin"
    get "/badge" => "pages#badge", :as => :pages_badge
    get "/💸", to: redirect("t/hiring")
    get "/survey", to: redirect("https://dev.to/ben/final-thoughts-on-the-state-of-the-web-survey-44nn")
    get "/events" => "events#index"
    get "/workshops", to: redirect("events")
    get "/sponsors" => "pages#sponsors"
    get "/search" => "stories#search"
    post "articles/preview" => "articles#preview"
    post "comments/preview" => "comments#preview"

    # These routes are required by links in the sites and will most likely to be replaced by a db page
    get "/about" => "pages#about"
    get "/about-listings" => "pages#about_listings"
    get "/security", to: "pages#bounty"
    get "/community-moderation" => "pages#community_moderation"
    get "/faq" => "pages#faq"
    get "/page/post-a-job" => "pages#post_a_job"
    get "/tag-moderation" => "pages#tag_moderation"

    # NOTE: can't remove the hardcoded URL here as SiteConfig is not available here, we should eventually
    # setup dynamic redirects, see <https://github.com/thepracticaldev/dev.to/issues/7267>
    get "/shop", to: redirect("https://shop.dev.to")

    get "/mod" => "moderations#index", :as => :mod
    get "/mod/:tag" => "moderations#index"
    get "/page/crayons" => "pages#crayons"

    post "/fallback_activity_recorder" => "ga_events#create"

    get "/page/:slug" => "pages#show"

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

    get "/settings/(:tab)" => "users#edit", :as => :user_settings
    get "/settings/:tab/:org_id" => "users#edit", :constraints => { tab: /organization/ }
    get "/settings/:tab/:id" => "users#edit", :constraints => { tab: /response-templates/ }
    get "/signout_confirm" => "users#signout_confirm"
    get "/dashboard" => "dashboards#show"
    get "/dashboard/pro", to: "dashboards#pro"
    get "dashboard/pro/org/:org_id", to: "dashboards#pro", as: :dashboard_pro_org
    get "dashboard/following" => "dashboards#following_tags"
    get "dashboard/following_tags" => "dashboards#following_tags"
    get "dashboard/following_users" => "dashboards#following_users"
    get "dashboard/following_organizations" => "dashboards#following_organizations"
    get "dashboard/following_podcasts" => "dashboards#following_podcasts"
    get "/dashboard/subscriptions" => "dashboards#subscriptions"
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

    get "/embed/:embeddable", to: "liquid_embeds#show", as: "liquid_embed"

    # serviceworkers
    get "/serviceworker" => "service_worker#index"
    get "/manifest" => "service_worker#manifest"

    # open search
    get "/open-search" => "open_search#show",
        :constraints => { format: /xml/ }

    get "/shell_top" => "shell#top"
    get "/shell_bottom" => "shell#bottom"

    get "/new" => "articles#new"
    get "/new/:template" => "articles#new"

    get "/pod", to: "podcast_episodes#index"
    get "/podcasts", to: redirect("pod")
    get "/readinglist" => "reading_list_items#index"
    get "/readinglist/:view" => "reading_list_items#index", :constraints => { view: /archive/ }

    get "/feed" => "articles#feed", :as => "feed", :defaults => { format: "rss" }
    get "/feed/tag/:tag" => "articles#feed", :as => "tag_feed", :defaults => { format: "rss" }
    get "/feed/:username" => "articles#feed", :as => "user_feed", :defaults => { format: "rss" }
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

    get "/badge/:slug" => "badges#show", :as => :badge

    get "/top/:timeframe" => "stories#index"

    get "/:timeframe" => "stories#index", :constraints => { timeframe: /latest/ }

    get "/:username/series" => "collections#index", :as => "user_series"
    get "/:username/series/:id" => "collections#show"

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
    get "/:username/:slug/actions_panel" => "moderations#actions_panel"
    get "/:username/:slug/manage" => "articles#manage"
    get "/:username/:slug/edit" => "articles#edit"
    get "/:username/:slug/delete_confirm" => "articles#delete_confirm"
    get "/:username/:slug/stats" => "articles#stats"
    get "/:username/:view" => "stories#index",
        :constraints => { view: /comments|moderate|admin/ }
    get "/:username/:slug" => "stories#show"
    get "/:sitemap" => "sitemaps#show",
        :constraints => { format: /xml/, sitemap: /sitemap-.+/ }
    get "/:username" => "stories#index", :as => "user_profile"

    root "stories#index"
  end
end

# rubocop:enable Metrics/BlockLength
