Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    session: "sessions",
    registrations: "registrations" }
  devise_scope :user do
    delete "/sign_out" => "devise/sessions#destroy"
    get "/enter" => "registrations#new", :as => :new_user_registration_path
  end

  namespace :admin do
    # Check administrate gem docs
    DashboardManifest::DASHBOARDS.each do |dashboard_resource|
      resources dashboard_resource
    end

    root controller: DashboardManifest::ROOT_DASHBOARD, action: :index
  end

  namespace :internal do
    resources :comments
    resources :articles
    resources :tags
    resources :welcome, only: [:index, :create]
    resources :broadcasts
    resources :users
    resources :events
    resources :dogfood, only: [:index]
    resources :buffer_updates, only: [:create]
    resources :articles, only: [:index, :update] do
      get "rss_articles", to: :rss_articles, on: :collection
    end
    resources :members, only: [:index]
    resources :events
    mount Flipflop::Engine => "/features"
  end


  namespace :api, defaults: {format: "json"} do
    scope module: :v0, constraints: ApiConstraints.new(version: 0, default: true) do
      resources :articles, only: [:index, :show] do
        collection do
          get "/onboarding", to: "articles#onboarding"
        end
      end
      resources :comments
      resources :podcast_episodes
      resources :reactions, only: [:create] do
        collection do
          post "/onboarding", to: "reactions#onboarding"
        end
      end
      resources :users, only: [:index, :show] do
        collection do
          get "/sidebar_suggestions", to: "users#sidebar_suggestions"
        end
      end
      resources :tags, only: [:index] do
        collection do
          get "/onboarding", to: "tags#onboarding"
        end
      end
      resources :follows, only: [:create]
    end
  end

  namespace :notifications do
    resources :counts, only: [:index]
    resources :reads, only: [:create]
  end

  resources :messages, only: [:create]
  resources :chat_channels, only: [:index, :show]
  resources :articles, only: [:update,:create,:destroy]
  resources :comments, only:[:create,:update,:destroy]
  resources :users, only:[:update]
  resources :reactions, only: [:index,:create]
  resources :feedback_messages, only: [:create]
  resources :organizations, only: [:update, :create]
  resources :followed_articles, only: [:index]
  resources :follows, only: [:index,:show,:create]
  resources :giveaways, only: [:create,:update]
  resources :image_uploads, only: [:create]
  resources :blocks
  resources :notifications, only: [:index]
  resources :tags, only: [:index]
  resources :analytics, only: [:index]
  resources :stripe_subscriptions, only: [:create, :update, :destroy]
  resources :stripe_active_cards, only: [:create, :update, :destroy]
  resources :live_articles, only: [:index]
  resources :github_repos, only: [:create, :update]
  resources :buffered_articles, only: [:index]
  resources :events, only: [:index, :show]
  resources :additional_content_boxes, only: [:index]
  resources :videos, only: [:create, :new]
  resources :video_states, only: [:create]
  resources :push_notification_subscriptions, only: [:create]
  
  get "/notifications/:username" => "notifications#index"
  patch "/onboarding_update" => "users#onboarding_update"
  get "email_subscriptions/unsubscribe"
  post "/chat_channels/:id/moderate" => "chat_channels#moderate"
  post "/chat_channels/:id/open" => "chat_channels#open"
  get "/connect" => "chat_channels#index"
  get "/connect/:slug" => "chat_channels#index"

  post "/pusher/auth" => "pusher#auth"

  # resources :users

  get "/social_previews/article/:id" => "social_previews#article"
  get "/social_previews/user/:id" => "social_previews#user"
  get "/social_previews/organization/:id" => "social_previews#organization"
  get "/social_previews/tag/:id" => "social_previews#tag"


  ### Subscription vanity url
  post "membership-action" => "stripe_subscriptions#create"

  get "/async_info/base_data", controller: "async_info#base_data", defaults: { format: :json }

  get "/hello-goodbye-to-the-go-go-go", to: redirect("ben/hello-goodbye-to-the-go-go-go")
  get "/dhh-on-the-future-of-rails", to: redirect("ben/dhh-on-the-future-of-rails")
  get "/christopher-chedeau-on-the-philosophies-of-react", to: redirect("ben/christopher-chedeau-on-the-philosophies-of-react")
  get "/javascript-fatigue-buzzword", to: redirect("ben/javascript-fatigue-buzzword")
  get "/chris-seaton-making-ruby-fast", to: redirect("ben/chris-seaton-making-ruby-fast")
  get "/communicating-intent-the-perpetually-misunderstood-ruby-bang", to: redirect("tom/communicating-intent-the-perpetually-misunderstood-ruby-bang")
  get "/quick-tip-grepping-rails-routes", to: redirect("tom/quick-tip-grepping-rails-routes")
  get "/use-cases-for-githubs-new-direct-upload-feature", to: redirect("ben/use-cases-for-githubs-new-direct-upload-feature")
  get "/this-blog-post-was-written-using-draft-js", to: redirect("ben/this-blog-post-was-written-using-draft-js")
  get "/the-future-of-software-development", to: redirect("ben/the-future-of-software-development")
  get "/the-zen-of-missing-out-on-the-next-great-programming-tool", to: redirect("ben/the-zen-of-missing-out-on-the-next-great-programming-tool")
  get "/the-joy-and-benefit-of-being-an-early-adopter-in-programming", to: redirect("ben/the-joy-and-benefit-of-being-an-early-adopter-in-programming")
  get "/watkinsmatthewp/every-developer-should-write-a-personal-automation-api", to: redirect("anotherdevblog/every-developer-should-write-a-personal-automation-api")

  # Settings
  post "users/join_org" => "users#join_org"
  post "users/leave_org" => "users#leave_org"
  post "users/add_org_admin" => "users#add_org_admin"
  post "users/remove_org_admin" => "users#remove_org_admin"
  post "users/remove_from_org" => "users#remove_from_org"
  post "organizations/generate_new_secret" => "organizations#generate_new_secret"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root
  get "/about" => "pages#about"
  get "/privacy" => "pages#privacy"
  get "/terms" => "pages#terms"
  get "/contact" => "pages#contact"
  get "/merch" => "pages#merch"
  get "/rlygenerator" => "pages#generator"
  get "/orlygenerator" => "pages#generator"
  get "/rlyslack" => "pages#generator"
  get "/rlytest" => "pages#rlytest"
  get "/rlyweb" => "pages#rlyweb"
  get "/rly" => "pages#rlyweb"
  get "/code-of-conduct" => "pages#code_of_conduct"
  get "/report-abuse" => "pages#report-abuse"
  get "/infiniteloop" => "pages#infinite_loop"
  get "/faq" => "pages#faq"
  get "/live" => "pages#live"
  get "/swagnets" => "pages#swagnets"
  get "/welcome" => "pages#welcome"
  get "/💸", to: redirect("t/hiring")
  get "/security", to: "pages#bounty"
  get "/phishing" => "pages#phishing"
  get "/now" => "pages#now"
  get "/membership" => "pages#membership"
  get "/events" => "events#index"
  get "/workshops", to: redirect("events")
  get "/sponsorship-info" => "pages#sponsorship_faq"
  get "/sponsors" => "pages#sponsors"
  get "/search" => "stories#search"
  post "articles/preview" => "articles#preview"
  post "comments/preview" => "comments#preview"
  get "/freestickers" => "giveaways#new"
  get "/freestickers/edit" => "giveaways#edit"
  get "/scholarship", to: redirect("/p/scholarships")
  get "/scholarships", to: redirect("/p/scholarships")
  get "/memberships", to: redirect("/membership")

  # For Google analytics tracking, but we don't want to
  # tip the trackers
  post "/cromulent" => "ga_events#create"

  scope "p" do
    %w(rly rlyweb welcome twitter_moniter editor_guide information markdown_basics scholarships wall_of_patrons membership_form badges).each do |action|
      get action, action: action, controller: "pages"
    end
  end

  get "/:user_board" => "users#index", :constraints => { user_board: /following|followers|leaderboard/}

  match "/delayed_job_admin" => DelayedJobWeb, :anchor => false, via: [:get, :post]

  match "/users/:id/finish_signup" => "users#finish_signup", via: [:get, :patch], :as => :finish_signup

  get "/settings/(:tab)" => "users#edit"
  get "/signout_confirm" => "users#signout_confirm"
  get "/dashboard" => "dashboards#show"
  get "/dashboard/:which" => "dashboards#show",
    constraints: { which: /organization|user_followers|following_users|reading/}
  get "/dashboard/:username" => "dashboards#show"

  get "/reactions/logged_out_reaction_counts" => "reactions#logged_out_reaction_counts"

  # for testing rails mailers
  if !Rails.env.production?
    get "/rails/mailers" => "rails/mailers#index"
    get "/rails/mailers/*path" => "rails/mailers#preview"
  end

  get "/new" => "articles#new"
  get "/new/:template" => "articles#new"

  get "/pod" => "podcast_episodes#index"
  get "/readinglist" => "reading_list_items#index"

  get "/feed" => "articles#feed", :as => "feed", :defaults => { :format => "rss" }
  get "/feed/:username" => "articles#feed", :as => "user_feed", :defaults => { :format => "rss" }
  get "/rss" => "articles#feed", :defaults => { :format => "rss" }

  get "/tag/:tag" => "stories#index"
  get "/t/:tag" => "stories#index"
  get "/t/:tag/edit", to: "tags#edit"
  patch "/tag/:id", to: "tags#update"
  get "/t/:tag/top/:timeframe" => "stories#index"
  get "/t/:tag/:timeframe" => "stories#index", constraints: { timeframe: /latest/}

  get "/badge/:slug" => "badges#show"

  get "/getting-started" => "onboarding#index"

  get "/top/:timeframe" => "stories#index"

  get "/:timeframe" => "stories#index", constraints: { timeframe: /latest/}

  #Lagacy comment format (might still be floating around app, and external links)
  get "/:username/:slug/comments/new/:parent_id_code" => "comments#new"
  get "/:username/:slug/comments/new" => "comments#new"
  get "/:username/:slug/comments" => "comments#index"
  get "/:username/:slug/comments/:id_code" => "comments#index"
  get "/:username/:slug/comments/:id_code/edit" => "comments#edit"
  get "/:username/:slug/comments/:id_code/delete_confirm" => "comments#delete_confirm"

  #Proper link format
  get "/:username/comment/:id_code" => "comments#index"
  get "/:username/comment/:id_code/edit" => "comments#edit"
  get "/:username/comment/:id_code/delete_confirm" => "comments#delete_confirm"
  get "/:username/comment/:id_code/mod" => "moderations#comment"


  get "/:username/:slug/:view" => "stories#show", constraints: { view: /moderate/}
  get "/:username/:slug/mod" => "moderations#article"
  get "/:username/:slug/edit" => "articles#edit"
  get "/:username/:slug/delete_confirm" => "articles#delete_confirm"
  get "/:username/:view" => "stories#index", constraints: { view: /comments|moderate|admin/}
  get "/:username/:slug" => "stories#show"
  get "/:username" => "stories#index"

  root "stories#index"
end
