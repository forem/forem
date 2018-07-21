class TwitterBot
  attr_reader :token, :secret

  def initialize(token:, secret:)
    @token = token
    @secret = secret
  end

  def client
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ApplicationConfig["TWITTER_KEY"]
      config.consumer_secret     = ApplicationConfig["TWITTER_SECRET"]
      config.access_token        = @token
      config.access_token_secret = @secret
    end
  end
end
