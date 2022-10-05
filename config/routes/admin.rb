# rubocop:disable Metrics/BlockLength
namespace :admin do
  get "/", to: "overview#index"

  authenticate :user, ->(user) { user.tech_admin? } do
    mount Blazer::Engine, at: "blazer"
    require "sidekiq/web"
    require "sidekiq_unique_jobs/web"
    require "sidekiq/cron/web"

    Sidekiq::Web.class_eval do
      use Rack::Protection, permitted_origins: [URL.url] # resolve Rack Protection HttpOrigin
    end

    mount Sidekiq::Web => "sidekiq"
    mount FieldTest::Engine, at: "abtests"
    get "abtests/experiments/:experiment_id/:goal", to: "/field_test/experiments#goal"

    flipper_ui = Flipper::UI.app(Flipper,
                                 { rack_protection: { except: %i[authenticity_token form_token json_csrf
                                                                 remote_token http_origin session_hijacking] } })
    mount flipper_ui, at: "feature_flags"
    mount PgHero::Engine, at: "pghero"
  end

  resources :organization_memberships, only: %i[update destroy create]
  resources :permissions, only: %i[index]
  resources :reactions, only: %i[update]
  resources :creator_settings, only: %i[create new]

  namespace :settings do
    resources :authentications, only: [:create]
    resources :campaigns, only: [:create]
    resources :communities, only: [:create]
    resources :general_settings, only: [:create]
    resources :mandatory_settings, only: [:create]
    resources :rate_limits, only: [:create]
    resources :smtp_settings, only: [:create]
    resources :user_experiences, only: [:create]
  end

  scope :member_manager do
    resources :users, only: %i[index show update destroy] do
      resources :email_messages, only: :show
      collection do
        get "export"
      end

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
        post "unpublish_all_articles"
      end
    end

    resources :invitations, only: %i[index new create destroy] do
      member do
        post "resend"
      end
    end

    resources :gdpr_delete_requests, only: %i[index destroy]
  end

  scope :content_manager do
    resources :spaces, only: %i[index update]
    resources :articles, only: %i[index show update] do
      member do
        delete :unpin
        post :pin
      end
    end

    resources :badges, only: %i[index edit update new create]
    resources :badge_achievements, only: %i[index destroy]
    get "/badge_achievements/award_badges", to: "badge_achievements#award"
    post "/badge_achievements/award_badges", to: "badge_achievements#award_badges"
    resources :comments, only: [:index]
    resources :organizations, only: %i[index show] do
      member do
        patch "update_org_credits"
      end
    end
    resources :podcasts, only: %i[index edit update destroy] do
      member do
        post :fetch
        post :add_owner
      end
    end
    resources :tags, only: %i[index new create update edit] do
      resource :moderator, only: %i[create destroy], module: "tags"
    end
  end

  scope :customization do
    # We renamed the controller but don't want to change the route (yet)
    resource :config, controller: "settings"
    resources :display_ads, only: %i[index edit update new create destroy]
    resources :html_variants, only: %i[index edit update new create show destroy]
    resources :navigation_links, only: %i[index update create destroy]
    resources :pages, only: %i[index new create edit update destroy]
    resources :profile_field_groups, only: %i[update create destroy]
    resources :profile_fields, only: %i[index update create destroy]
  end

  scope :moderation do
    resources :feedback_messages, only: %i[index show]
    resources :reports, only: %i[index show], controller: "feedback_messages" do
      collection do
        post "send_email"
        post "create_note"
        post "save_status"
      end
    end
    resources :mods, only: %i[index update]
    resources :moderator_actions, only: %i[index]
    resources :privileged_reactions, only: %i[index]
  end

  scope :advanced do
    resources :broadcasts
    resources :response_templates, only: %i[index new edit create update destroy]
    resources :secrets, only: %i[index]
    put "secrets", to: "secrets#update"
    resources :tools, only: %i[index create] do
      collection do
        post "bust_cache"
        get "feed_playground"
        post "feed_playground"
      end
    end

    resources :extensions, only: %i[index] do
      collection do
        post "toggle", to: "extensions#toggle"
      end
    end

    # We do not expose the Data Update Scripts to all Forems by default.
    constraints(->(_request) { FeatureFlag.enabled?(:data_update_scripts) }) do
      resources :data_update_scripts, only: %i[index show] do
        member do
          post :force_run
        end
      end
    end
  end

  scope :apps do
    resources :consumer_apps, only: %i[index new create edit update destroy]
    resources :welcome, only: %i[index create]
  end
end
# rubocop:enable Metrics/BlockLength
