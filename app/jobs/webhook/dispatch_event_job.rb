module Webhook
  class DispatchEventJob < ApplicationJob
    queue_as :dispatch_webhook_events

    def perform(endpoint_url:, payload:, client: HTTParty)
      uri = URI.parse(endpoint_url)
      client.post(uri, headers: { "Content-Type" => "application/json" }, body: payload)
    end
  end
end
