require "timber-rails/active_record/log_subscriber"

module Timber
  module Integrations
    # Module for holding *all* ActiveRecord integrations. See {Integration} for
    # configuration details for all integrations.
    module ActiveRecord
      extend Integration

      def self.integrate!
        return false if !enabled?

        LogSubscriber.integrate!
      end
    end
  end
end
