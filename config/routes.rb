# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  # Devise does not support scoping omniauth callbacks under a dynamic segment
  # so this lives outside our i18n scope.
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    registrations: "registrations",
    invitations: "invitations",
    passwords: "passwords",
    confirmations: "confirmations",
    passwordless: "devise/passwordless/sessions"
  }

  devise_scope :user do
    get "/enter", to: "registrations#new", as: :sign_up
    get "/confirm-email", to: "confirmations#new"
    delete "/sign_out", to: "devise/sessions#destroy"
  end

  # This route makes default Ahoy Email redirect URLs available to us
  # However, we monkeypatch this behavior in config/initializers/ahoy_email.rb so this
  # routes is not currently where emails pass through.
  mount AhoyEmail::Engine => "/ahoy"

  # Custom controller for tracking clicks asynchronously
  namespace :ahoy do
    post "email_clicks", to: "email_clicks#create"
  end

  get "/r/mobile", to: "deep_links#mobile"
  get "/.well-known/apple-app-site-association", to: "deep_links#aasa"

  # [@forem/delightful] - all routes are nested under this optional scope to
  # begin supporting i18n.
  scope "(/locale/:locale)", defaults: { locale: nil } do
    get "/locale/:locale", to: "stories#index"

    draw :admin

    # The lambda (e.g. `->`) allows for dynamic checking.  In other words we check with each
    # request.
    constraints(->(_req) { Listing.feature_enabled? }) do
      draw :listing
    end

    namespace :stories, defaults: { format: "json" } do
      resource :feed, only: [:show] do
        resource :pinned_article, only: %w[show update destroy]

        get ":timeframe", to: "feeds#show", as: :timeframe
      end
    end

    namespace :api, defaults: { format: "json" } do
      scope module: :v1, constraints: ApiConstraints.new(version: 1, default: false) do
        # V1 only endpoints
        put "/articles/:id/unpublish", to: "articles#unpublish", as: :article_unpublish
        put "/users/:id/unpublish", to: "users#unpublish", as: :user_unpublish

        get "/users/search", to: "users#search"

        post "/reactions", to: "reactions#create"
        post "/reactions/toggle", to: "reactions#toggle"

        resources :recommended_articles_lists, only: %i[index show create update]

        resources :billboards, only: %i[index show create update] do
          put "unpublish", on: :member
        end
        # temporary keeping both routes while transitioning (renaming) display_ads => billboards
        resources :display_ads, only: %i[index show create update], controller: :billboards do
          put "unpublish", on: :member
        end

        resources :segments, controller: "audience_segments", only: %i[index show create destroy] do
          get "users", on: :member
          put "add_users", on: :member
          put "remove_users", on: :member
        end

        resources :pages, only: %i[index show create update destroy]

        resources :organizations, only: %i[index create update destroy]

        scope("/users/:id") do
          constraints(role: /suspend|suspended|limited|spam|trusted/) do
            put "/:role", to: "user_roles#update", as: "user_add_role"
          end

          constraints(role: /limited|spam|trusted/) do
            delete "/:role", to: "user_roles#destroy", as: "user_remove_role"
          end
        end

        draw :api
      end

      scope module: :v0, constraints: ApiConstraints.new(version: 0, default: true) do
        draw :api
      end
    end

    namespace :notifications do
      resources :counts, only: [:index]
      resources :reads, only: [:create]
    end

    namespace :incoming_webhooks do
      get "/mailchimp/:secret/unsubscribe", to: "mailchimp_unsubscribes#index", as: :mailchimp_unsubscribe_check
      post "/mailchimp/:secret/unsubscribe", to: "mailchimp_unsubscribes#create", as: :mailchimp_unsubscribe
      resources :stripe_events, only: [:create]
    end

    resources :magic_links, only: [:create]

    resources :messages, only: [:create]
    resources :articles, only: %i[update create destroy] do
      patch "/admin_unpublish", to: "articles#admin_unpublish"
      patch "/admin_featured_toggle", to: "articles#admin_featured_toggle"
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
    resources :users, only: %i[index show], defaults: { format: :json } do # internal API
      member do
        put "spam", to: "users#toggle_spam"
        delete "spam", to: "users#toggle_spam"
      end
      collection do
        resources :devices, only: %i[create destroy]
      end
    end
    namespace :users do
      resource :settings, only: %i[update]
      resource :notification_settings, only: %i[update]
    end
    resources :users, only: %i[update]
    resources :reactions, only: %i[index create]
    resources :response_templates, only: %i[index create edit update destroy]
    resources :feedback_messages, only: %i[index create]
    resources :organizations, only: %i[update create destroy]
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
        get "/suggest", to: "tags#suggest", defaults: { format: :json }
        get "/bulk", to: "tags#bulk", defaults: { format: :json }
      end
    end
    resources :stripe_active_cards, only: %i[create update destroy]
    resources :stripe_subscriptions, only: %i[new edit destroy]
    resources :github_repos, only: %i[index] do
      collection do
        post "/update_or_create", to: "github_repos#update_or_create"
      end
    end
    resources :videos, only: %i[index create new]
    resources :video_states, only: [:create]
    resources :twilio_tokens, only: [:show]
    resources :tag_adjustments, only: %i[create destroy]
    resources :rating_votes, only: [:create]
    resources :page_views, only: %i[create update]
    resources :feed_events, only: %i[create]
    resources :credits, only: %i[index new create] do
      get "purchase", on: :collection, to: "credits#new"
    end
    resources :reading_list_items, only: [:update]
    resources :poll_votes, only: %i[show create]
    resources :poll_skips, only: [:create]
    resources :profile_pins, only: %i[create update]
    # temporary keeping both routes while transitioning (renaming) display_ads => billboards
    resources :display_ad_events, only: [:create], controller: :billboard_events
    resources :billboard_events, only: [:create]
    # Alias for reporting in case "events" triggers spam filters
    post "/bb_tabulations", to: "billboard_events#create", as: :bb_tabulations

    resources :badges, only: [:index]
    resources :user_blocks, param: :blocked_id, only: %i[show create destroy]
    resources :podcasts, only: %i[new create]
    resources :article_approvals, only: %i[create]
    resources :sidebars, only: %i[show]
    resources :profile_preview_cards, only: %i[show]
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

    resource :onboarding, only: %i[show update] do
      member do
        patch :checkbox, defaults: { format: :json }
        patch :notifications, defaults: { format: :json }
        get :tags, defaults: { format: :json }
        get :users_and_organizations, defaults: { format: :json }
        get :newsletter, defaults: { format: :json }
      end
    end

    resources :profiles, only: %i[update]
    resources :profile_field_groups, only: %i[index], defaults: { format: :json }

    resources :liquid_tags, only: %i[index], defaults: { format: :json }

    resources :discussion_locks, only: %i[create destroy]

    get "/verify_email_ownership", to: "email_authorizations#verify", as: :verify_email_authorizations
    get "/search/tags", to: "search#tags"
    get "/search/usernames", to: "search#usernames"
    get "/search/feed_content", to: "search#feed_content"
    get "/search/reactions", to: "search#reactions"
    get "/notifications/:filter", to: "notifications#index", as: :notifications_filter
    get "/notifications/:filter/:org_id", to: "notifications#index", as: :notifications_filter_org
    get "/notification_subscriptions/:notifiable_type/:notifiable_id", to: "notification_subscriptions#show"
    post "/notification_subscriptions/:notifiable_type/:notifiable_id", to: "notification_subscriptions#upsert"
    get "email_subscriptions/unsubscribe"

    get "/internal", to: redirect("/admin")
    get "/internal/:path", to: redirect("/admin/%{path}")

    get "/async_info/base_data", to: "async_info#base_data", defaults: { format: :json }
    get "/async_info/navigation_links", to: "async_info#navigation_links"

    get "auth_pass/iframe", to: "auth_pass#iframe", as: :auth_pass_iframe
    post "auth_pass/token_login", to: "auth_pass#token_login", as: :auth_pass_token_login

    # Billboards
    scope "/:username/:slug" do
      get "/billboards/:placement_area", to: "billboards#show", as: :article_billboard
      # temporary keeping both routes while transitioning (renaming) display_ads => billboards
      get "/display_ads/:placement_area", to: "billboards#show"
    end
    get "/billboards/:placement_area", to: "billboards#show", as: :billboard
    # temporary keeping both routes while transitioning (renaming) display_ads => billboards
    get "/display_ads/:placement_area", to: "billboards#show"

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

    # Internal Admin API
    # put "/users/:id/spam", to: "users#toggle_spam", as: :user_toggle_spam
    # delete "/users/:id/spam", to: "users#toggle_spam", as: :user_toggle_spam

    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".

    # You can have the root of your site routed with "root
    get "/robots.:format", to: "pages#robots"
    get "/api", to: redirect("https://developers.forem.com/api")
    get "/privacy", to: "pages#privacy"
    get "/terms", to: "pages#terms"
    get "/contact", to: "pages#contact"
    get "/code-of-conduct", to: "pages#code_of_conduct"
    get "/report-abuse", to: "pages#report_abuse"
    get "/welcome", to: "pages#welcome"
    get "/challenge", to: "pages#challenge"
    get "/checkin", to: "pages#checkin"
    get "/💸", to: redirect("t/hiring")
    get "/survey", to: redirect("https://dev.to/ben/final-thoughts-on-the-state-of-the-web-survey-44nn")
    get "/search", to: "stories/articles_search#index"
    get "/:slug/members", to: "organizations#members", as: :organization_members
    post "articles/preview", to: "articles#preview"
    post "comments/preview", to: "comments#preview"
    post "comments/subscribe", to: "notification_subscriptions#create"
    post "subscription/unsubscribe", to: "notification_subscriptions#destroy"

    # These routes are required by links in the sites and will most likely to be replaced by a db page
    get "/about", to: "pages#about"
    get "/security", to: "pages#bounty"
    get "/community-moderation", to: "pages#community_moderation"
    get "/faq", to: "pages#faq"
    get "/page/post-a-job", to: "pages#post_a_job"
    get "/tag-moderation", to: "pages#tag_moderation"

    get "/mod", to: "moderations#index", as: :mod
    get "/mod/:tag", to: "moderations#index"

    post "/fallback_activity_recorder", to: "ga_events#create"

    get "/page/:slug", to: "pages#show"

    scope "p" do
      pages_actions = %w[welcome editor_guide publishing_from_rss_guide markdown_basics].freeze
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
    get "/dashboard/sidebar", to: "dashboards#sidebar"
    get "/dashboard/analytics", to: "dashboards#analytics"
    get "dashboard/analytics/org/:org_id", to: "dashboards#analytics", as: :dashboard_analytics_org
    get "dashboard/following", to: "dashboards#following_tags"
    get "dashboard/following_tags", to: "dashboards#following_tags"
    get "dashboard/following_users", to: "dashboards#following_users"
    get "dashboard/following_organizations", to: "dashboards#following_organizations"
    get "dashboard/following_podcasts", to: "dashboards#following_podcasts"
    get "dashboard/hidden_tags", to: "dashboards#hidden_tags"
    get "/dashboard/subscriptions", to: "dashboards#subscriptions"
    get "/dashboard/:which", to: "dashboards#followers", constraints: { which: /user_followers/ }
    get "/dashboard/:which/:org_id", to: "dashboards#show",
                                     constraints: {
                                       which: /organization/
                                     }
    get "/dashboard/:username", to: "dashboards#show", as: :dashboard_show_user

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

    get "/tag/:tag", to: "stories/tagged_articles#index"
    get "/t/:tag", to: "stories/tagged_articles#index", as: :tag
    get "/t/:tag/top/:timeframe", to: "stories/tagged_articles#index"
    get "/t/:tag/page/:page", to: "stories/tagged_articles#index"
    get "/t/:tag/:timeframe", to: "stories/tagged_articles#index",
                              constraints: { timeframe: /latest/ }


    get "/t/:tag/edit", to: "tags#edit", as: :edit_tag
    get "/t/:tag/admin", to: "tags#admin"
    patch "/tag/:id", to: "tags#update"

    get "/top/:timeframe", to: "stories#index"

    get "/:feed_type/:timeframe", to: "stories#index", constraints: { feed_type: /following/, timeframe: /latest/  }

    get "/:timeframe", to: "stories#index", constraints: { timeframe: /latest/ }
    get "/:feed_type", to: "stories#index", constraints: { feed_type: /discover|following/}

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
                                  constraints: { view: /moderate|admin/ }
    get "/:username/:slug/mod", to: "moderations#article"
    get "/:username/:slug/actions_panel", to: "moderations#actions_panel"
    get "/:username/:slug/manage", to: "articles#manage", as: :article_manage
    get "/:username/:slug/edit", to: "articles#edit"
    get "/:username/:slug/delete_confirm", to: "articles#delete_confirm"
    get "/:username/:slug/discussion_lock_confirm", to: "articles#discussion_lock_confirm"
    get "/:username/:slug/discussion_unlock_confirm", to: "articles#discussion_unlock_confirm"
    get "/:username/:slug/stats", to: "articles#stats"
    get "/:username/:view", to: "stories#index",
                            constraints: { view: /comments|moderate|admin/ }
    get "/:username/:slug", to: "stories#show"
    get "/:sitemap", to: "sitemaps#show",
                     constraints: { format: /xml/, sitemap: /sitemap-.+/ }
    get "/:username", to: "stories#index", as: "user_profile", # No txt format
                      constraints: { format: /html/ }
    get "/:slug", to: "pages#show",
                  constraints: { format: /txt/ }
    get "/:slug_0/:slug_1", to: "pages#show", as: :page_0_1
    get "/:slug_0/:slug_1/:slug_2", to: "pages#show", as: :page_0_1_2
    get "/:slug_0/:slug_1/:slug_2/:slug_3", to: "pages#show", as: :page_0_1_2_3
    get "/:slug_0/:slug_1/:slug_2/:slug_3/:slug_4", to: "pages#show", as: :page_0_1_2_3_4
    get "/:slug_0/:slug_1/:slug_2/:slug_3/:slug_4/:slug_5", to: "pages#show", as: :page_0_1_2_3_4_5
    root "stories#index"
  end
end

# rubocop:enable Metrics/BlockLength
