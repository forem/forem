module Webhook
  class DispatchEvent
    def initialize(event_type, record)
      @event_type = event_type
      @record = record
    end

    def self.call(...)
      new(...).call
    end

    def call
      endpoint_urls = Endpoint.for_events([event_type]).where(user_id: record.user_id).pluck(:target_url)
      return if endpoint_urls.empty?

      event_json = Event.new(event_type: event_type, payload: PayloadAdapter.new(record).hash).to_json
      endpoint_urls.each do |url|
        DispatchEventWorker.perform_async(url, event_json)
      end
    end

    private

    attr_reader :event_type, :record
  end
end
