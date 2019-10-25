module Audit
  class SaveToPersistentStorageJob < ApplicationJob
    queue_as :audit_logs

    def perform(event_string)
      Audit::Event::Util.deserialize(event_string).
        then { |event| build_params(event) }.
        then { |params| AuditLog.create!(params) }
    end

    def build_params(event)
      {
        user_id: event.payload[:user_id],
        roles: event.payload[:roles],
        slug: event.payload[:slug],
        category: event.name,
        data: event.payload[:data]
      }
    end
  end
end
