class TwitterBot

  def initialize(identity=nil)
    if identity
      token = identity.token
      secret = identity.secret
    else
      token = ENV["TWITTER_KEY"]
      secret = ENV["TWITTER_SECRET"]
    end
    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_KEY"]
      config.consumer_secret     = ENV["TWITTER_SECRET"]
      config.access_token        = token
      config.access_token_secret = secret
    end
  end

  def client
    @twitter
  end

end
