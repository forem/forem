module Webhook
  class Event
    EVENT_TYPES = %w[
      article_created
      article_updated
      article_destroyed
    ].freeze

    def initialize(event_name, payload = {})
      @event_name = event_name
      @payload = payload
    end

    private

    attr_reader :event_name, :payload
  end
end
