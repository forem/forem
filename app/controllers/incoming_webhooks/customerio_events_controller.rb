module IncomingWebhooks
  # Restores the local click signal (ahoy_messages.clicked_at) for emails
  # rendered/sent by Customer.io, which never hit Ahoy's own click-tracking
  # route. Deliverability metrics (bounced/spammed/delivered/etc.) are owned
  # by mlh-core's Reporting Webhook and are intentionally ignored here.
  class CustomerioEventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    CLICKED_METRIC = "clicked".freeze
    SIGNATURE_HEADER = "X-CIO-Signature".freeze
    TIMESTAMP_HEADER = "X-CIO-Timestamp".freeze

    def create
      raw_body = request.raw_post

      return head :unauthorized unless valid_signature?(raw_body)

      payload = JSON.parse(raw_body)
      handle_clicked(payload) if payload["metric"] == CLICKED_METRIC

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error("IncomingWebhooks::CustomerioEventsController: invalid JSON (#{e.message})")
      head :ok
    end

    private

    def handle_clicked(payload)
      delivery_id = payload.dig("data", "delivery_id")
      return if delivery_id.blank?

      Customerio::RecordEmailClickWorker.perform_async(delivery_id, payload["timestamp"])
    end

    def valid_signature?(raw_body)
      signing_key = ApplicationConfig["CUSTOMERIO_WEBHOOK_SIGNING_KEY"]
      return false if signing_key.blank?

      signature = request.headers[SIGNATURE_HEADER]
      timestamp = request.headers[TIMESTAMP_HEADER]
      return false if signature.blank? || timestamp.blank?

      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", signing_key, "v0:#{timestamp}:#{raw_body}")
      ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
    end
  end
end
