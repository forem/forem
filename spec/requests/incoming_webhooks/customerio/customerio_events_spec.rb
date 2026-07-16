require "rails_helper"

RSpec.describe "IncomingWebhooks::CustomerioEventsController" do
  let(:signing_key) { "whsec_test_signing_key" }
  let(:timestamp) { "1700000000" }

  def signature_for(raw_body, hmac_key: signing_key, event_ts: timestamp)
    OpenSSL::HMAC.hexdigest("SHA256", hmac_key, "v0:#{event_ts}:#{raw_body}")
  end

  def post_event(payload, hmac_key: signing_key, event_ts: timestamp, signature: nil)
    raw_body = payload.to_json
    sig = signature || signature_for(raw_body, hmac_key: hmac_key, event_ts: event_ts)

    post "/incoming_webhooks/customerio/events",
         params: raw_body,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-CIO-Signature" => sig,
           "X-CIO-Timestamp" => event_ts
         }
  end

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_WEBHOOK_SIGNING_KEY").and_return(signing_key)
    allow(Customerio::RecordEmailClickWorker).to receive(:perform_async)
  end

  describe "POST /incoming_webhooks/customerio/events" do
    let(:clicked_payload) do
      {
        "metric" => "clicked",
        "object_type" => "email",
        "timestamp" => 1_700_000_100,
        "data" => { "delivery_id" => "delivery-123" }
      }
    end

    it "enqueues the click worker and returns 200 for a validly signed clicked event" do
      post_event(clicked_payload)

      expect(response).to have_http_status(:ok)
      expect(Customerio::RecordEmailClickWorker).to have_received(:perform_async).with("delivery-123", 1_700_000_100)
    end

    it "returns 200 and does not enqueue anything for a validly signed non-click metric" do
      post_event(clicked_payload.merge("metric" => "delivered"))

      expect(response).to have_http_status(:ok)
      expect(Customerio::RecordEmailClickWorker).not_to have_received(:perform_async)
    end

    it "returns 200 and does not enqueue when a clicked event has no delivery_id" do
      post_event(clicked_payload.merge("data" => {}))

      expect(response).to have_http_status(:ok)
      expect(Customerio::RecordEmailClickWorker).not_to have_received(:perform_async)
    end

    it "returns 401 when the signature is missing" do
      raw_body = clicked_payload.to_json
      post "/incoming_webhooks/customerio/events",
           params: raw_body,
           headers: { "CONTENT_TYPE" => "application/json", "X-CIO-Timestamp" => timestamp }

      expect(response).to have_http_status(:unauthorized)
      expect(Customerio::RecordEmailClickWorker).not_to have_received(:perform_async)
    end

    it "returns 401 when the signature does not match" do
      post_event(clicked_payload, signature: "0" * 64)

      expect(response).to have_http_status(:unauthorized)
      expect(Customerio::RecordEmailClickWorker).not_to have_received(:perform_async)
    end

    it "returns 401 when the signing key is not configured" do
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_WEBHOOK_SIGNING_KEY").and_return(nil)

      post_event(clicked_payload)

      expect(response).to have_http_status(:unauthorized)
      expect(Customerio::RecordEmailClickWorker).not_to have_received(:perform_async)
    end
  end
end
