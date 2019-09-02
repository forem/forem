module Webhook
  class EventSerializer
    include FastJsonapi::ObjectSerializer
    set_type :webhook_event
    set_id do |event|
      "#{event.event_type}_#{event.timestamp}"
    end
    attributes :event_type, :timestamp, :payload
  end
end
