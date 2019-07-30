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

  class << self
    def fetch(id)
      retry_on_error(4) { get(id, tweet_mode: "extended") }
    end

    def get(id, options = {})
      client.status(id, options)
    end

    def client
      @client ||= TwitterBot.new(random_identity).client
    end

    private

    def random_identity
      identity = Identity.where(provider: "twitter").last(250).sample

      {
        token: identity&.token || ApplicationConfig["TWITTER_ACCESS_TOKEN"],
        secret: identity&.secret || ApplicationConfig["TWITTER_ACCESS_TOKEN_SECRET"]
      }
    end

    def retry_on_error(retry_count, &block)
      yield(block)
    rescue Twitter::Error => e
      if retry_count.positive?
        sleep 0.2
        retry_count -= 1
        Rails.logger.error(e)
        Rails.logger.info "Retry reading tweet status. (#{retry_count} retry left) .."
        retry
      else
        Rails.logger.warn "Failed to read tweet status"
        nil
      end
    end
  end
end
