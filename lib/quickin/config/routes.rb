Quickin::Engine.routes.draw do
  # This should only be available in a development environment, it allows
  # a developer to circumvent the auth process. See
  # lib/quickin/app/controllers/user_controller_decorator.rb for more.
  get "/" => "users#quickin"
end
