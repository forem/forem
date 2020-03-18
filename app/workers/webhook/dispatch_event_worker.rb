module Webhook
  class DispatchEventWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority

    def perform(endpoint_url, event_json)
      uri = Addressable::URI.parse(endpoint_url)
      HTTParty.post(uri, headers: { "Content-Type" => "application/json" }, body: event_json, timeout: 10)
    end
  end
end
