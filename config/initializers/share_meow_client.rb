ShareMeowClient.configuration do |config|
  config.base_url = ApplicationConfig["SHARE_MEOW_BASE_URL"]
  config.secret_key = ApplicationConfig["SHARE_MEOW_SECRET_KEY"]
end
