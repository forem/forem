# We preload the authentication module on initialization
# to make sure providers are correctly preloaded
# both in development and in production and ready to be used when needed
# at runtime
Dir[Rails.root.join("app/services/authentication/**/*.rb")].each do |f|
  require_dependency(f)
end
