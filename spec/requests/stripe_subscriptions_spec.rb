require "rails_helper"

RSpec.describe "StripeSubscriptions" do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_api_key) { Settings::General.stripe_api_key }
  let(:default_item_code) { ENV.fetch("STRIPE_BASE_ITEM_CODE", "default_code") }
  let(:subscription_success_url) { ENV["SUBSCRIPTION_SUCCESS_URL"] || "/settings/billing" }
  let(:session_url) { "https://checkout.stripe.com/pay/test_session_id" }

  describe "GET /stripe_subscriptions/new" do
    context "when the user is not signed in" do
      it "redirects to the sign in page" do
        get new_stripe_subscription_path

        expect(response).to redirect_to("/enter")
      end
    end

    context "when the user is signed in" do
      before do
        StripeMock.start
        sign_in user
        allow(Stripe::Checkout::Session).to receive(:create).and_return(OpenStruct.new(url: session_url))
      end

      after { StripeMock.stop }

      it "creates a new Stripe Checkout Session and redirects to the session URL" do
        get new_stripe_subscription_path, params: { item: default_item_code }

        expect(Stripe::Checkout::Session).to have_received(:create).with(
          line_items: [
            {
              price: default_item_code,
              quantity: 1
            },
          ],
          mode: "subscription",
          success_url: URL.url(subscription_success_url),
          cancel_url: URL.url("/settings/billing"),
          customer_email: user.email,
          metadata: {
            user_id: user.id
          },
        )

        expect(response).to redirect_to(session_url)
      end

      it "allows other host redirection" do
        get new_stripe_subscription_path, params: { item: default_item_code }
        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to eq(session_url)
      end

      context "with custom parameters" do
        let(:custom_item_code) { "custom_item_code" }
        let(:custom_mode) { "payment" }

        it "creates a Stripe Checkout Session with custom parameters" do
          get new_stripe_subscription_path, params: { item: custom_item_code, mode: custom_mode }

          expect(Stripe::Checkout::Session).to have_received(:create).with(
            line_items: [
              {
                price: custom_item_code,
                quantity: 1
              },
            ],
            mode: custom_mode,
            success_url: URL.url(subscription_success_url),
            cancel_url: URL.url("/settings/billing"),
            customer_email: user.email,
            metadata: {
              user_id: user.id
            },
          )

          expect(response).to redirect_to(session_url)
        end
      end
    end
  end
end
