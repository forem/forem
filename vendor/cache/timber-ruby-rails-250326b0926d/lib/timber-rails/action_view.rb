require "timber-rails/action_view/log_subscriber"

module Timber
  module Integrations
    # Module for holding *all* ActionView integrations. See {Integration} for
    # configuration details for all integrations.
    module ActionView
      extend Integration

      def self.integrate!
        return false if !enabled?

        LogSubscriber.integrate!
      end
    end
  end
end
