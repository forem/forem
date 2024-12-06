# frozen_string_literals: true

module Lumberjack
  module Rack
    class UnitOfWork
      def initialize(app)
        @app = app
      end

      def call(env)
        Lumberjack.unit_of_work do
          @app.call(env)
        end
      end
    end
  end
end
