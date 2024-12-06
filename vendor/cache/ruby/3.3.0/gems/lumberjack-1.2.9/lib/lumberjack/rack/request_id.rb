# frozen_string_literals: true

module Lumberjack
  module Rack
    # Support for using the Rails ActionDispatch request id in the log.
    # The format is expected to be a random UUID and only the first chunk is used for terseness
    # if the abbreviated argument is true.
    class RequestId
      REQUEST_ID = "action_dispatch.request_id"

      def initialize(app, abbreviated = false)
        @app = app
        @abbreviated = abbreviated
      end

      def call(env)
        request_id = env[REQUEST_ID]
        if request_id && @abbreviated
          request_id = request_id.split("-", 2).first
        end
        Lumberjack.unit_of_work(request_id) do
          @app.call(env)
        end
      end
    end
  end
end
