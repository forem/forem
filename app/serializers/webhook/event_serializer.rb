module Webhook
  class EventSerializer < ApplicationSerializer
    set_type :webhook_event
    set_id :event_id

    attributes :event_type, :timestamp, :payload
  end
end
