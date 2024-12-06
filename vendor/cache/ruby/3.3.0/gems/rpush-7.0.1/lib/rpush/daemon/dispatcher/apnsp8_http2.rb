module Rpush
  module Daemon
    module Dispatcher
      class Apnsp8Http2
        include Loggable
        include Reflectable

        URLS = {
          production: 'https://api.push.apple.com',
          development: 'https://api.sandbox.push.apple.com',
          sandbox: 'https://api.sandbox.push.apple.com'
        }

        DEFAULT_TIMEOUT = 60

        def initialize(app, delivery_class, _options = {})
          @app = app
          @delivery_class = delivery_class

          @client = create_http2_client(app)
          @token_provider = Rpush::Daemon::Apnsp8::Token.new(@app)
        end

        def dispatch(payload)
          @delivery_class.new(@app, @client, @token_provider, payload.batch).perform
        end

        def cleanup
          @client.close
        end

        private

        def create_http2_client(app)
          url = URLS[app.environment.to_sym]
          client = NetHttp2::Client.new(url, connect_timeout: DEFAULT_TIMEOUT)
          client.on(:error) do |error|
            log_error(error)
            reflect(:error, error)
          end
          client
        end
      end
    end
  end
end
