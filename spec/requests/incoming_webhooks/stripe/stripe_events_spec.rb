require "rails_helper"

RSpec.describe "IncomingWebhooks::StripeEventsController", type: :request do
  let(:stripe_endpoint_secret) { "whsec_test_secret" }
  let(:headers) { { "HTTP_STRIPE_SIGNATURE" => stripe_signature } }
  let(:user) { create(:user) }

  before do
    allow(Settings::General).to receive(:stripe_api_key).and_return(stripe_endpoint_secret)
  end

  describe "POST /incoming_webhooks/stripe_events" do
    let(:stripe_signature) { "test_signature" }

    context "with a valid event" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      end

      shared_examples "a successful stripe event" do
        it "returns status :ok" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("status")
        end
      end

      context "when invoice.payment_succeeded" do
        let(:payload) { { "type" => "invoice.payment_succeeded", "data" => { "object" => { "metadata" => { "user_id" => user.id } } } }.to_json }
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "adds the base_subscriber role to the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload.base_subscriber?).to be_truthy
        end
      end

      context "when customer.subscription.created" do
        let(:payload) { { "type" => "customer.subscription.created", "data" => { "object" => { "metadata" => { "user_id" => user.id } } } }.to_json }
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "adds the base_subscriber role to the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload.base_subscriber?).to be_truthy
        end
      end

      context "when customer.subscription.updated" do
        let(:payload) { { "type" => "customer.subscription.updated", "data" => { "object" => { "metadata" => { "user_id" => user.id } } } }.to_json }
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "adds the base_subscriber role to the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload.base_subscriber?).to be_truthy
        end
      end

      context "when customer.subscription.deleted" do
        let(:payload) { { "type" => "customer.subscription.deleted", "data" => { "object" => { "metadata" => { "user_id" => user.id } } } }.to_json }
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "removes the base_subscriber role from the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload.base_subscriber?).to be_falsey
        end
      end
    end

    context "with an invalid payload" do
      let(:payload) { "invalid_payload" }

      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError)
      end

      it "returns status :bad_request" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Invalid payload")
      end
    end

    context "with an invalid signature" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new("Invalid signature", "sig"))
      end

      let(:payload) { { "type" => "invoice.payment_succeeded", "data" => { "object" => { "metadata" => { "user_id" => user.id } } } }.to_json }

      it "returns status :bad_request" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Invalid signature")
      end
    end
  end
end
