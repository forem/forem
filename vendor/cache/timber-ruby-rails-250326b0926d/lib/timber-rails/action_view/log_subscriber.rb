module Timber
  module Integrations
    module ActionView
      # Reponsible for uninstalling the default `ActionView::LogSubscriber` and installing
      # the TimberLogSubscriber.
      #
      # @private
      class LogSubscriber < Integrator
        def initialize
          require "action_view/log_subscriber"
          require "timber-rails/action_view/log_subscriber/timber_log_subscriber"
        rescue LoadError => e
          raise RequirementNotMetError.new(e.message)
        end

        def integrate!
          return true if Timber::Integrations::Rails::ActiveSupportLogSubscriber.subscribed?(:action_view, TimberLogSubscriber)

          Timber::Integrations::Rails::ActiveSupportLogSubscriber.unsubscribe!(:action_view, ::ActionView::LogSubscriber)
          TimberLogSubscriber.attach_to(:action_view)
        end
      end
    end
  end
end
