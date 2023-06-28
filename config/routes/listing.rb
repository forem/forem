namespace :admin do
  scope :apps do
    resources :listings, only: %i[index edit update destroy]
    resources :listing_categories, only: %i[index edit update new create
                                            destroy], path: "listings/categories"
  end
end

namespace :api, defaults: { format: "json" } do
  scope module: :v1, constraints: ApiConstraints.new(version: 1, default: false) do
    resources :listings, only: %i[index show create update]
    get "/listings/category/:category", to: "listings#index", as: :listings_category
    get "/organizations/:organization_username/listings", to: "organizations#listings",
                                                          as: :organization_listings
  end

  scope module: :v0, constraints: ApiConstraints.new(version: 0, default: true) do
    resources :listings, only: %i[index show create update]
    get "/listings/category/:category", to: "listings#index"
    get "/organizations/:organization_username/listings", to: "organizations#listings"
  end
end
resources :listings, only: %i[index new create edit update destroy dashboard]

get "/search/listings", to: "search#listings"
get "/listings/dashboard", to: "listings#dashboard"
get "/listings/:category", to: "listings#index", as: :listing_category
get "/listings/:category/:slug", to: "listings#index", as: :listing_slug
get "/listings/:category/:slug/:view", to: "listings#index", constraints: { view: /moderate/ }
get "/listings/:category/:slug/delete_confirm", to: "listings#delete_confirm"
delete "/listings/:category/:slug", to: "listings#destroy"
get "/social_previews/listing/:id", to: "social_previews#listing", as: :listing_social_preview
get "/about-listings", to: "pages#about_listings"
