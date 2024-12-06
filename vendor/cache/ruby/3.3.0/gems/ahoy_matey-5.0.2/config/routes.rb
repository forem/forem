Rails.application.routes.draw do
  mount Ahoy::Engine => "/ahoy" if Ahoy.api
end

Ahoy::Engine.routes.draw do
  scope module: "ahoy" do
    resources :visits, only: [:create]
    resources :events, only: [:create]
  end
end
