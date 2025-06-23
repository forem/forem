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
    allow(NotifyMailer).to receive_message_chain(:with, :base_subscriber_role_email, :deliver_now)
  end

  describe "POST /incoming_webhooks/stripe_events" do
    let(:stripe_signature) { "test_signature" }
    before { allow(Stripe::Webhook).to receive(:construct_event).and_return(event) }

    shared_examples "a successful stripe event" do
      it "returns status :ok" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("status")
      end
    end

    context "when checkout.session.completed" do
      let(:payload) do
        {
          "type" => "checkout.session.completed",
          "data" => {
            "object" => {
              "metadata" => { "user_id" => user.id.to_s }
            }
          }
        }.to_json
      end
      let(:event) { JSON.parse(payload) }
      before { last_billboard_event }

      it_behaves_like "a successful stripe event"

      it "grants the base_subscriber role" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(user.reload.roles.pluck(:name)).to include("base_subscriber")
      end

      it "creates a conversion BillboardEvent" do
        expect {
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        }.to change(BillboardEvent, :count).by(1)

        new_ev = BillboardEvent.last
        expect(new_ev.category).to eq("conversion")
        expect(new_ev.geolocation).to eq(last_billboard_event.geolocation)
        expect(new_ev.context_type).to eq(last_billboard_event.context_type)
        expect(new_ev.billboard_id).to eq(last_billboard_event.billboard_id)
      end

      it "sends the subscriber role email" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(NotifyMailer).to have_received(:with).with(user: user)
        expect(NotifyMailer.with(user: user).base_subscriber_role_email).to have_received(:deliver_now)
      end

      it "skips conversion when the click is too old" do
        last_billboard_event.update(created_at: 4.hours.ago)
        expect {
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        }.not_to change(BillboardEvent, :count)
      end

      context "with a customer id present" do
        let(:customer_id) { "cus_TEST123" }
        let(:payload) do
          {
            "type" => "checkout.session.completed",
            "data" => {
              "object" => {
                "metadata" => { "user_id" => user.id.to_s },
                "customer" => customer_id
              }
            }
          }.to_json
        end
        let(:event) { JSON.parse(payload) }

        it "stores stripe_id_code on the user" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload.stripe_id_code).to eq(customer_id)
        end
      end
    end

    context "when customer.subscription.updated" do
      context "and cancel_at_period_end is true" do
        let(:payload) do
          {
            "type" => "customer.subscription.updated",
            "data" => {
              "object" => {
                "metadata" => {
                  "user_id" => user.id.to_s,
                  "cancel_at_period_end" => true
                }
              }
            }
          }.to_json
        end
        let(:event) { JSON.parse(payload) }

        it_behaves_like "a successful stripe event"

        it "adds the impending_base_subscriber_cancellation role" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          expect(user.reload.roles.pluck(:name)).to include("impending_base_subscriber_cancellation")
        end
      end

      context "and cancel_at_period_end is false" do
        let(:payload) do
          {
            "type" => "customer.subscription.updated",
            "data" => {
              "object" => {
                "metadata" => {
                  "user_id" => user.id.to_s,
                  "cancel_at_period_end" => false
                }
              }
            }
          }.to_json
        end
        let(:event) { JSON.parse(payload) }

        it "ensures the user has only the base_subscriber role" do
          post "/incoming_webhooks/stripe_events", params: payload, headers: headers
          names = user.reload.roles.pluck(:name)
          expect(names).to include("base_subscriber")
          expect(names).not_to include("impending_base_subscriber_cancellation")
        end
      end
    end

    context "when customer.subscription.deleted" do
      let(:payload) do
        {
          "type" => "customer.subscription.deleted",
          "data" => {
            "object" => {
              "metadata" => { "user_id" => user.id.to_s }
            }
          }
        }.to_json
      end
      let(:event) { JSON.parse(payload) }

      it_behaves_like "a successful stripe event"

      it "adds the impending_base_subscriber_cancellation role" do
        post "/incoming_webhooks/stripe_events", params: payload, headers: headers
        expect(user.reload.roles.pluck(:name)).to include("impending_base_subscriber_cancellation")
      end
    end
  end
end
