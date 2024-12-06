module Flipper
  module UI
    # Internal: Used to detect the action that should be used in the middleware.
    class ActionCollection
      def initialize
        @action_classes = []
      end

      def add(action_class)
        @action_classes << action_class
      end

      def action_for_request(request)
        @action_classes.detect do |action_class|
          action_class.route_match?(request.path_info)
        end
      end
    end
  end
end
