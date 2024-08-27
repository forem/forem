require "rails_helper"

RSpec.describe "StripeSubscriptions" do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_api_key) { Settings::General.stripe_api_key }
  let(:default_item_code) { ENV.fetch("STRIPE_BASE_ITEM_CODE", "default_code") }
  let(:tag_moderator_item_code) { ENV.fetch("STRIPE_TAG_MODERATOR_ITEM_CODE", "tag_moderator_code") }
  let(:subscription_success_url) { ENV["SUBSCRIPTION_SUCCESS_URL"] || "/settings/billing" }
  let(:session_url) { "https://checkout.stripe.com/pay/test_session_id" }

  describe "GET /stripe_subscriptions/new" do
    before do
      ENV["STRIPE_BASE_ITEM_CODE"] = "default_code"
      ENV["STRIPE_TAG_MODERATOR_ITEM_CODE"] = "tag_moderator_code"
    end

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

      context "when the user is a tag moderator" do
        before do
          allow(user).to receive(:tag_moderator?).and_return(true)
        end

        it "uses the tag moderator item code" do
          get new_stripe_subscription_path

          expect(Stripe::Checkout::Session).to have_received(:create).with(
            line_items: [
              {
                price: tag_moderator_item_code,
                quantity: 1
              },
            ],
            mode: "subscription",
            success_url: URL.url(subscription_success_url),
            cancel_url: URL.url("/settings/billing"),
            consent_collection: {
              terms_of_service: "required"
            },
            customer_email: user.email,
            metadata: {
              user_id: user.id
            },
          )

          expect(response).to redirect_to(session_url)
        end
      end

      context "when the user is not a tag moderator" do
        before { allow(user).to receive(:tag_moderator?).and_return(false) }

        it "uses the provided item code if it is different from the tag moderator item code" do
          custom_item_code = "custom_item_code"
          get new_stripe_subscription_path, params: { item: custom_item_code }

          expect(Stripe::Checkout::Session).to have_received(:create).with(
            line_items: [
              {
                price: custom_item_code,
                quantity: 1
              },
            ],
            mode: "subscription",
            success_url: URL.url(subscription_success_url),
            cancel_url: URL.url("/settings/billing"),
            consent_collection: {
              terms_of_service: "required"
            },
            customer_email: user.email,
            metadata: {
              user_id: user.id
            },
          )

          expect(response).to redirect_to(session_url)
        end

        it "falls back to the default item code if no valid item code is provided" do
          get new_stripe_subscription_path

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
            consent_collection: {
              terms_of_service: "required"
            },
            customer_email: user.email,
            metadata: {
              user_id: user.id
            },
          )

          expect(response).to redirect_to(session_url)
        end
      end

      it "allows other host redirection" do
        get new_stripe_subscription_path
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
            consent_collection: {
              terms_of_service: "required"
            },
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
