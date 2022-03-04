module Audit
  class Notification
    ##
    # Main class for wrapping ActiveSupport Instrumentation API.
    #
    # This class represent main entry point for receiving and notifying custom
    # events, implemented according to
    # https://guides.rubyonrails.org/active_support_instrumentation.html#creating-custom-events

    class << self
      include Audit::Helper

      ##
      # Audit::Notification.notify method, receives listener name, which is registered through
      # Audit::Notification.listen and the event payload, passed as a block.
      #
      # Object of Audit::Event::Payload is send to the block as argument. This way,
      # the payload object follows the rules defined in Audit::Event::Payload
      #
      # Example:
      # Audit::Notification.notify('listener_name') do |payload|
      #   payload.user_id = current_user.id
      #   payload.roles = current_user.roles.pluck(:name)
      # end

      def notify(listener, &block)
        return unless block

        ActiveSupport::Notifications.instrument(instrument_name(listener), Audit::Event::Payload.new(&block))
      end

      ##
      # Audit::Notification.listen receives Events sent from ActiveSupport Instrumentation API.
      # Then, this event is serialized and send to background job.

      def listen(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        AuditLog.create!(params_hash(event))
      end

      def params_hash(event)
        {
          user_id: event.payload.user_id,
          roles: event.payload.roles,
          slug: event.payload.slug,
          category: event.name,
          data: event.payload.data
        }
      end
    end
  end
end
