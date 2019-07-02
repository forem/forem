module Moderator
  module Audit
    class Notification
      AuditConfig = Moderator::Audit::Application.config

      def initialize(payload)
        @payload = payload
      end

      def instrument
        ActiveSupport::Notifications.instrument(AuditConfig.instrumentation_name, @payload)
      end

      class << self
        def subscribe(*_args)
          # Save event to DB
          # event = ActiveSupport::Notifications::Event.new(*args)

          Rails.logger.info "Moderator::Audit::Notification.subscribe Event Received!"
        end
      end
    end
  end
end
