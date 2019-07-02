module Moderator
  module Audit
    class Subscribe
      include Singleton
      AuditConfig = Moderator::Audit::Application.config

      ActiveSupport::Notifications.subscribe(AuditConfig.instrumentation_name) do |*args|
        Moderator::Audit::Notification.subscribe(*args)
      end
    end
  end
end
