module Github
  # Github client (uses ocktokit.rb as a backend)
  class Client
    class << self
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

      private

      def request
        Honeycomb.add_field("app.name", "github.client")
        yield
      rescue Octokit::Error => e
        class_name = e.class.name.demodulize

        record_error(e.message, class_name)

        # raise specific error if known, generic one if unknown
        error_class = "::Github::Errors::#{class_name}".safe_constantize
        raise error_class, e.message if error_class

        error_class = if e.class < Octokit::ClientError
                        Github::Errors::ClientError
                      elsif e.class < Octokit::ServerError
                        Github::Errors::ServerError
                      else
                        Github::Errors::Error
                      end

        raise error_class, e.message
      end

      def record_error(error_message, class_name)
        Honeycomb.add_field("github.result", "error")
        Honeycomb.add_field("github.error", class_name)
        DatadogStatsClient.increment(
          "github.errors",
          tags: ["error:#{class_name}", "message:#{error_message}"],
        )
      end

      def target
        @target ||= Octokit::Client.new(
          client_id: ApplicationConfig["GITHUB_KEY"],
          client_secret: ApplicationConfig["GITHUB_SECRET"],
          user_agent: "#{Octokit::Default::USER_AGENT} (#{URL.url})",
          middleware: faraday_middleware_stack,
          connection_options: connection_options,
        )
      end

      def faraday_middleware_stack
        # Extending the default functionality
        # see <https://github.com/octokit/octokit.rb#advanced-usage>
        # and <https://github.com/octokit/octokit.rb/blob/master/lib/octokit/default.rb>
        Faraday::RackBuilder.new do |builder|
          # parts of the default
          builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
          builder.use Octokit::Middleware::FollowRedirects
          builder.use Octokit::Response::RaiseError
          builder.use Octokit::Response::FeedParser

          # customizations
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
end
