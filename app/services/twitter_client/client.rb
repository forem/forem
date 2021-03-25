module TwitterClient
  # Twitter client (users twitter gem as a backend)
  class Client
    class << self
      # adapted from https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to
      def method_missing(method, *args, &block)
        return super unless target.respond_to?(method, false)

        request do
          target.public_send(method, *args, &block)
        end
      end

      # adapted from https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to
      def respond_to_missing?(method, _include_all = false)
        target.respond_to?(method, false) || super
      end

      private

      def request
        Honeycomb.add_field("name", "twitter.client")
        yield
      rescue Twitter::Error => e
        record_error(e)
        handle_error(e)
      end

      def record_error(exception)
        class_name = exception.class.name.demodulize

        Honeycomb.add_field("twitter.result", "error")
        Honeycomb.add_field("twitter.error", class_name)
        ForemStatsClient.increment(
          "twitter.errors",
          tags: ["error:#{class_name}", "message:#{exception.message}"],
        )
      end

      def handle_error(exception)
        class_name = exception.class.name.demodulize

        # raise specific error if known, generic one if unknown
        error_class = "::TwitterClient::Errors::#{class_name}".safe_constantize
        raise error_class, exception.message if error_class

        error_class = if exception.class < Twitter::Error::ClientError
                        TwitterClient::Errors::ClientError
                      elsif exception.class < Twitter::Error::ServerError
                        TwitterClient::Errors::ServerError
                      else
                        TwitterClient::Errors::Error
                      end

        raise error_class, exception.message
      end

      def target
        Twitter::REST::Client.new(
          consumer_key: SiteConfig.twitter_key.presence || ApplicationConfig["TWITTER_KEY"],
          consumer_secret: SiteConfig.twitter_secret.presence || ApplicationConfig["TWITTER_SECRET"],
          user_agent: "TwitterRubyGem/#{Twitter::Version} (#{URL.url})",
          timeouts: {
            connect: 5,
            read: 5,
            write: 5
          },
        )
      end
    end
  end
end
