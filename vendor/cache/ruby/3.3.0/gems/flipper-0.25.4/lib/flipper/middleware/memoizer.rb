module Flipper
  module Middleware
    class Memoizer
      # Public: Initializes an instance of the Memoizer middleware. Flipper must
      # be configured with a default instance or the flipper instance must be
      # setup in the env of the request. You can do this by using the
      # Flipper::Middleware::SetupEnv middleware.
      #
      # app - The app this middleware is included in.
      # opts - The Hash of options.
      #        :preload - Boolean to preload all features or Array of Symbol feature names to preload.
      #
      # Examples
      #
      #   use Flipper::Middleware::Memoizer
      #
      #   # using with preload_all features
      #   use Flipper::Middleware::Memoizer, preload: true
      #
      #   # using with preload specific features
      #   use Flipper::Middleware::Memoizer, preload: [:stats, :search, :some_feature]
      #
      def initialize(app, opts = {})
        if opts.is_a?(Flipper::DSL) || opts.is_a?(Proc)
          raise 'Flipper::Middleware::Memoizer no longer initializes with a flipper instance or block. Read more at: https://git.io/vSo31.'
        end

        @app = app
        @opts = opts
        @env_key = opts.fetch(:env_key, 'flipper')
      end

      def call(env)
        request = Rack::Request.new(env)

        if memoize?(request)
          memoized_call(env)
        else
          @app.call(env)
        end
      end

      private

      def memoize?(request)
        if @opts[:if]
          @opts[:if].call(request)
        elsif @opts[:unless]
          !@opts[:unless].call(request)
        else
          true
        end
      end

      def memoized_call(env)
        reset_on_body_close = false
        flipper = env.fetch(@env_key) { Flipper }

        # Already memoizing. This instance does not need to do anything.
        if flipper.memoizing?
          warn "Flipper::Middleware::Memoizer appears to be running twice. Read how to resolve this at https://github.com/jnunemaker/flipper/pull/523"
          return @app.call(env)
        end

        flipper.memoize = true

        case @opts[:preload]
        when true then flipper.preload_all
        when Array then flipper.preload(@opts[:preload])
        end

        @app.call(env)
      ensure
        flipper.memoize = false if flipper
      end
    end
  end
end
