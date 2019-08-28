module Webhook
  class DispatchEventJob < ApplicationJob
    queue_as :dispatch_webhook_events

    def perform(endpoint_url:, payload:)
      uri = URI.parse(endpoint_url)
      HTTParty.post(uri, headers: {}, body: payload)
    end
  end
end
