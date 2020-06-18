Rails.application.config.to_prepare do
  # We require all authentication modules to make sure providers
  # are correctly preloaded and ready to be used at this point as the loading
  # order is important
  Dir[Rails.root.join("app/services/authentication/**/*.rb")].each do |f|
    require_dependency(f)
  end
end
