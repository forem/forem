class TwitterBot
  def self.client(token:, secret:)
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ApplicationConfig["TWITTER_KEY"]
      config.consumer_secret     = ApplicationConfig["TWITTER_SECRET"]
      config.access_token        = token
      config.access_token_secret = secret
    end
  end
end
