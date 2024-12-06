FieldTest::Engine.routes.draw do
  resources :experiments, only: [:show]
  resources :memberships, only: [:update]
  get "participants/:id", to: "participants#show", constraints: {id: /.+/}, as: :legacy_participant
  get "participants", to: "participants#show", as: :participant
  root "experiments#index"
end
