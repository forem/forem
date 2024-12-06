RailsApp::Application.routes.draw do
  devise_for :users
  devise_scope :user do
    resource :free_invitation, only: [:new, :create]
    resource :admin, only: [:new, :create]
  end
  devise_for :admins
  root to: 'home#index'
end
