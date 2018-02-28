ShareMeowClient.configuration do |config|
  config.base_url = ENV["SHARE_MEOW_BASE_URL"]
  config.secret_key = ENV["SHARE_MEOW_SECRET_KEY"]
end
