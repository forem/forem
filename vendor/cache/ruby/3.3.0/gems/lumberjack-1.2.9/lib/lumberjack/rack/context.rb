# frozen_string_literals: true

module Lumberjack
  module Rack
    # Middleware to create a global context for Lumberjack for the scope of a rack request.
    class Context
      def initialize(app)
        @app = app
      end

      def call(env)
        Lumberjack.context do
          @app.call(env)
        end
      end
    end
  end
end
