module Github
  # Github OAuth2 client (uses ocktokit.rb as a backend)
  class OauthClient
    APP_AUTH_CREDENTIALS = %i[client_id client_secret].freeze

    # @param credentials [Hash] the OAuth credentials, {client_id:, client_secret:} or {access_token:}
    def initialize(credentials)
      @credentials = check_credentials!(credentials)
    end

    def self.for_user(user)
      access_token = user.identities.github.select(:token).take!.token
      new(access_token: access_token)
    end

    # Hides private credentials when printed
    def inspect
      "#<#{self.class.name}:#{object_id}>"
    end

    private

    attr_reader :credentials

    # adapted from https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to
    def method_missing(method, *args, &block)
      return super unless target.respond_to?(method, false)

      # define for re-use
      self.class.define_method(method) do |*new_args, &new_block|
        request do
          target.public_send(method, *new_args, &new_block)
        end
      end

      # call the original method, this will only be called the first time
      # as in subsequent calls, the newly defined method will prevail
      request do
        target.public_send(method, *args, &block)
      end
    end

    # adapted from https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to
    def respond_to_missing?(method, _include_all = false)
      target.respond_to?(method, false) || super
    end

    def check_credentials!(credentials)
      if credentials.present?
        return credentials.select { |k| k == :access_token } if credentials[:access_token].present?

        all_auth_credentials = proc { |key, value| APP_AUTH_CREDENTIALS.include?(key) && value.present? }
        return credentials.select { |key| APP_AUTH_CREDENTIALS.include?(key) } if credentials.all?(all_auth_credentials)
      end

      message = "The client either needs a valid 'client_id'/'client_secret' pair or an 'access_token'!"
      raise ArgumentError, message
    end

    def request
      Honeycomb.add_field("app.name", "github.client")
      yield
    rescue Octokit::Error, Octokit::InvalidRepository => e
      record_error(e)
      handle_error(e)
    end

    def record_error(exception)
      class_name = exception.class.name.demodulize

      Honeycomb.add_field("github.result", "error")
      Honeycomb.add_field("github.error", class_name)
      DatadogStatsClient.increment(
        "github.errors",
        tags: ["error:#{class_name}", "message:#{exception.message}"],
      )
    end

    def handle_error(exception)
      class_name = exception.class.name.demodulize

      # raise specific error if known, generic one if unknown
      error_class = "::Github::Errors::#{class_name}".safe_constantize
      raise error_class, exception.message if error_class

      error_class = if exception.class < Octokit::ClientError
                      Github::Errors::ClientError
                    elsif exception.class < Octokit::ServerError
                      Github::Errors::ServerError
                    else
                      Github::Errors::Error
                    end

      raise error_class, exception.message
    end

    def target
      @target ||= Octokit::Client.new(params.merge(credentials))
    end

    def params
      {
        user_agent: "#{Octokit::Default::USER_AGENT} (#{URL.url})",
        middleware: faraday_middleware_stack,
        connection_options: connection_options
      }
    end

    def faraday_middleware_stack
      # Extending the default functionality
      # see <https://github.com/octokit/octokit.rb#advanced-usage>,
      # <https://github.com/octokit/octokit.rb#caching>
      # and <https://github.com/octokit/octokit.rb/blob/master/lib/octokit/default.rb>
      Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, store: Rails.cache, serializer: Marshal, shared_cache: false
        builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
        builder.use Octokit::Middleware::FollowRedirects
        builder.use Octokit::Response::RaiseError
        builder.use Octokit::Response::FeedParser

        builder.response :logger if Rails.env.development?
        builder.adapter :patron
      end
    end

    def connection_options
      Octokit.connection_options.merge(
        request: {
          open_timeout: 5,
          timeout: 5
        },
      )
    end
  end
end
