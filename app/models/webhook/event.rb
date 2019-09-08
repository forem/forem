module Webhook
  class Event
    EVENT_TYPES = %w[
      article_created
      article_updated
      article_destroyed
    ].freeze

    attr_reader :event_type, :payload, :timestamp, :event_id

    def initialize(event_type:, payload: {})
      raise InvalidEvent unless EVENT_TYPES.include?(event_type)

      @event_type = event_type
      @payload = payload

      now = Time.current
      @timestamp = now.rfc3339
      @event_id = Secrets::Generator.sortable(now)
    end

    def as_json(*_args)
      Webhook::EventSerializer.new(self).serializable_hash
    end
  end

  class InvalidEvent < StandardError; end
end
