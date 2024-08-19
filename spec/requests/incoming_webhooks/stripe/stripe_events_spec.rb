require "rails_helper"

RSpec.describe "IncomingWebhooks::StripeEventsController" do
  let(:stripe_endpoint_secret) { "whsec_test_secret" }
  let(:headers) { { "HTTP_STRIPE_SIGNATURE" => stripe_signature } }
  let(:user) { create(:user) }
  let(:billboard) { create(:billboard) }
  let(:last_billboard_event) do
    create(
      :billboard_event,
      user: user,
      category: "click",
      created_at: 30.minutes.ago,
      context_type: "home",
      billboard_id: billboard.id,
    )
  end

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

      context "when checkout.session.completed" do
        let(:payload) do
          { "type" => "checkout.session.completed",
            "data" => { "object" => { "metadata" => { "user_id" => user.id.to_s } } } }.to_json
        end
        let(:event) { JSON.parse(payload) }

        before { last_billboard_event } # Ensure the last billboard event exists

        it_behaves_like "a successful stripe event"

        it "adds the base_subscriber role to the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload).to be_base_subscriber
        end

        it "creates a BillboardEvent with category 'conversion'" do
          expect do
            post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          end.to change(BillboardEvent, :count).by(1)

          new_event = BillboardEvent.last
          expect(new_event.user_id).to eq(user.id)
          expect(new_event.category).to eq("conversion")
          expect(new_event.geolocation).to eq(last_billboard_event.geolocation)
          expect(new_event.context_type).to eq(last_billboard_event.context_type)
          expect(new_event.billboard_id).to eq(last_billboard_event.billboard_id)
        end

        it "does not create a BillboardEvent if there is no recent click event" do
          last_billboard_event.update(created_at: 2.hours.ago) # Make it too old

          expect do
            post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          end.not_to change(BillboardEvent, :count)
        end
      end

      context "when customer.subscription.created" do
        let(:payload) do
          { "type" => "customer.subscription.created",
            "data" => { "object" => { "metadata" => { "user_id" => user.id.to_s } } } }.to_json
        end
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "adds the base_subscriber role to the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload).to be_base_subscriber
        end
      end

      context "when customer.subscription.updated" do
        let(:payload) do
          { "type" => "customer.subscription.updated",
            "data" => { "object" => { "metadata" => { "user_id" => user.id.to_s } } } }.to_json
        end
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "adds the base_subscriber role to the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload).to be_base_subscriber
        end
      end

      context "when customer.subscription.deleted" do
        let(:payload) do
          { "type" => "customer.subscription.deleted",
            "data" => { "object" => { "metadata" => { "user_id" => user.id.to_s } } } }.to_json
        end
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "removes the base_subscriber role from the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload).not_to be_base_subscriber
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
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::SignatureVerificationError.new("Invalid signature", "sig"))
      end

      let(:payload) do
        { "type" => "checkout.session.completed",
          "data" => { "object" => { "metadata" => { "user_id" => user.id.to_s } } } }.to_json
      end

      it "returns status :bad_request" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Invalid signature")
      end
    end
  end
end
