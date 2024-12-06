# frozen_string_literal: true

module Capybara
  class Server
    class Middleware
      class Counter
        def initialize
          @value = []
          @mutex = Mutex.new
        end

        def increment(uri)
          @mutex.synchronize { @value.push(uri) }
        end

        def decrement(uri)
          @mutex.synchronize { @value.delete_at(@value.index(uri) || @value.length) }
        end

        def positive?
          @mutex.synchronize { @value.length.positive? }
        end

        def value
          @mutex.synchronize { @value.dup }
        end
      end

      attr_reader :error

      def initialize(app, server_errors, extra_middleware = [])
        @app = app
        @extended_app = extra_middleware.inject(@app) do |ex_app, klass|
          klass.new(ex_app)
        end
        @counter = Counter.new
        @server_errors = server_errors
      end

      def pending_requests
        @counter.value
      end

      def pending_requests?
        @counter.positive?
      end

      def clear_error
        @error = nil
      end

      def call(env)
        if env['PATH_INFO'] == '/__identify__'
          [200, {}, [@app.object_id.to_s]]
        else
          request_uri = env['REQUEST_URI']
          @counter.increment(request_uri)

          begin
            @extended_app.call(env)
          rescue *@server_errors => e
            @error ||= e
            raise e
          ensure
            @counter.decrement(request_uri)
          end
        end
      end
    end
  end
end
