module Webhook
  class DispatchEventJob < ApplicationJob
    queue_as :webhook_dispatch_events

    def perform(endpoint_url:, payload:, client: HTTParty)
      uri = Addressable::URI.parse(endpoint_url)
      client.post(uri, headers: { "Content-Type" => "application/json" }, body: payload, timeout: 10)
    end
  end
end
