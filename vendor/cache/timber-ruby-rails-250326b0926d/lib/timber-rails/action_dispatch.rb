require "timber-rails/action_dispatch/debug_exceptions"

module Timber
  module Integrations
    # Module for holding *all* ActionDispatch integrations. This
    # module simply disables the exception tracking middleware so that our middleware
    # works as expected.
    module ActionDispatch
      def self.enabled?
        Rails::ErrorEvent.enabled?
      end

      def self.integrate!
        return false if !enabled?

        DebugExceptions.integrate!
      end
    end
  end
end
