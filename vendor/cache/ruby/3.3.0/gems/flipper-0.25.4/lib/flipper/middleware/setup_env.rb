module Flipper
  module Middleware
    class SetupEnv
      # Public: Initializes an instance of the SetupEnv middleware. Allows for
      # lazy initialization of the flipper instance being set in the env by
      # providing a block.
      #
      # app - The app this middleware is included in.
      # flipper_or_block - The Flipper::DSL instance or a block that yields a
      #                    Flipper::DSL instance to use for all operations
      #                    (optional, default: Flipper).
      #
      # Examples
      #
      #   flipper = Flipper.new(...)
      #
      #   # using with a normal flipper instance
      #   use Flipper::Middleware::SetupEnv, flipper
      #
      #   # using with a block that yields a flipper instance
      #   use Flipper::Middleware::SetupEnv, lambda { Flipper.new(...) }
      #
      #   # using default configured Flipper instance
      #   Flipper.configure do |config|
      #     config.default { Flipper.new(...) }
      #   end
      #   use Flipper::Middleware::SetupEnv
      def initialize(app, flipper_or_block = nil, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')

        if flipper_or_block.respond_to?(:call)
          @flipper_block = flipper_or_block
        else
          @flipper = flipper_or_block || Flipper
        end
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        env[@env_key] ||= flipper
        @app.call(env)
      end

      private

      def flipper
        @flipper ||= @flipper_block.call
      end
    end
  end
end
