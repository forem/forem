namespace :api, defaults: { format: "json" } do
  scope module: :v1, constraints: ApiConstraints.new(version: 1, default: false) do
    resources :listings, only: %i[index show create update]
    get "/listings/category/:category", to: "listings#index", as: :listings_category
    get "/organizations/:organization_id_or_slug/listings", to: "organizations#listings",
                                                            as: :organization_listings
  end

  scope module: :v0, constraints: ApiConstraints.new(version: 0, default: true) do
    resources :listings, only: %i[index show create update]
    get "/listings/category/:category", to: "listings#index"
    get "/organizations/:organization_id_or_slug/listings", to: "organizations#listings"
  end
end