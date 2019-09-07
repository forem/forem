module Webhook
  class Event
    EVENT_TYPES = %w[
      article_created
      article_updated
      article_destroyed
    ].freeze

    attr_reader :event_type, :payload, :timestamp

    def initialize(event_type:, payload: {})
      raise InvalidEvent unless EVENT_TYPES.include?(event_type)

      @event_type = event_type
      @payload = payload
      @timestamp = Time.current.rfc3339
    end

    def as_json(*_args)
      Webhook::EventSerializer.new(self).serializable_hash
    end
  end

  class InvalidEvent < StandardError; end
end
