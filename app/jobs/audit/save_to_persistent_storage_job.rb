module Audit
  class SaveToPersistentStorageJob < ApplicationJob
    queue_as :audit_logs

    def perform(event_string)
      event = Audit::Event::Util.deserialize(event_string)

      AuditLog.create!(user_id: event.dig(:payload, :user_id), roles: event.dig(:payload, :roles))
    end
  end
end
