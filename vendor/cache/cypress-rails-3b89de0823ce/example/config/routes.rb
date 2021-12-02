Rails.application.routes.draw do
  get "/an_static_form", to: "forms#static"
  get "/external_request", to: "static_pages#external"

  resources :compliments

  root "compliments#index"
end
