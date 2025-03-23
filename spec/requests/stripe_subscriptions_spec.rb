require "rails_helper"

RSpec.describe "StripeSubscriptions" do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_api_key) { Settings::General.stripe_api_key }
  let(:default_item_code) { ENV.fetch("STRIPE_BASE_ITEM_CODE", "default_code") }
  let(:tag_moderator_item_code) { ENV.fetch("STRIPE_TAG_MODERATOR_ITEM_CODE", "tag_moderator_code") }
  let(:subscription_success_url) { ENV["SUBSCRIPTION_SUCCESS_URL"] || "/settings/billing" }
  let(:billing_portal_return_url) { ENV["BILLING_PORTAL_RETURN_URL"] || "/settings/billing" }
  let(:session_url) { "https://checkout.stripe.com/pay/test_session_id" }
  let(:portal_session_url) { "https://billing.stripe.com/session/test_portal_session_id" }

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

  describe "GET /stripe_subscriptions/edit" do
    before do
      StripeMock.start
      Stripe.api_key = stripe_api_key
    end

    after { StripeMock.stop }

    context "when the user is not signed in" do
      it "redirects to the sign-in page" do
        get edit_stripe_subscription_path("me")
        expect(response).to redirect_to("/enter")
      end
    end

    context "when the user is signed in" do
      before { sign_in user }

      context "when the user has a Stripe customer ID" do
        before do
          user.update(stripe_id_code: "cus_test123")
          allow(Stripe::BillingPortal::Session).to receive(:create).and_return(OpenStruct.new(url: portal_session_url))
        end

        it "creates a Stripe Billing Portal session and redirects to it" do
          get edit_stripe_subscription_path("me")

          expect(Stripe::BillingPortal::Session).to have_received(:create).with(
            customer: user.stripe_id_code,
            return_url: URL.url(billing_portal_return_url)
          )

          expect(response).to redirect_to(portal_session_url)
          expect(response).to have_http_status(:found)
          expect(response.headers["Location"]).to eq(portal_session_url)
        end
      end

      context "when the user does not have a Stripe customer ID" do
        it "shows an error message and redirects back" do
          get edit_stripe_subscription_path("me")

          expect(flash[:error]).to eq("Unable to edit subscription self-serve. Please contact support.")
          expect(response).to redirect_to(user_settings_path)
        end
      end
    end
  end


  describe "DELETE /stripe_subscriptions/destroy" do
    before do
      StripeMock.start
      sign_in user
      Stripe.api_key = stripe_api_key
    end

    after { StripeMock.stop }

    context "when the user is not signed in" do
      before { sign_out user }

      it "redirects to the sign in page" do
        delete stripe_subscription_path("me"), params: { verification: "pleasecancelmyplusplus" }
        expect(response).to redirect_to("/enter")
      end
    end

    context "when the user is signed in" do
      context "when the verification parameter is correct and the user has a Stripe customer ID" do
        before do
          # Create a mock product and price
          price = Stripe::Price.create(
            unit_amount: 2000,
            currency: "usd",
            product: stripe_helper.create_product.id,
          )

          # Create a mock customer
          customer = Stripe::Customer.create(email: user.email)

          # Add a mock payment source to the customer
          Stripe::Customer.create_source(
            customer.id,
            { source: stripe_helper.generate_card_token },
          )

          user.update(stripe_id_code: customer.id)

          # Create a mock subscription using the created price
          subscription = Stripe::Subscription.create(
            customer: customer.id,
            items: [{ price: price.id }],
          )
        end

        it "cancels the subscription and removes the base subscriber role" do
          expect(Stripe::Subscription).to receive(:update).and_call_original
          expect(user).to receive(:remove_role).with("base_subscriber").and_call_original

          delete stripe_subscription_path("me"), params: { verification: "pleasecancelmyplusplus" }

          expect(response).to redirect_to(user_settings_path)
          expect(flash[:notice]).to eq("Your subscription has been canceled.")
        end
      end

      context "when the verification parameter is incorrect" do
        before { user.update(stripe_id_code: "fake_customer_id") }

        it "does not cancel the subscription and shows an alert" do
          expect(Stripe::Subscription).not_to receive(:update)

          delete stripe_subscription_path("me"), params: { verification: "wrong_verification" }

          expect(response).to redirect_to(user_settings_path)
          expect(flash[:error]).to eq("Invalid verification parameter. Subscription was not canceled.")
        end
      end

      context "when the user does not have a Stripe customer ID" do
        it "does not cancel the subscription and shows an alert" do
          delete stripe_subscription_path("me"), params: { verification: "pleasecancelmyplusplus" }

          expect(response).to redirect_to(user_settings_path)
          expect(flash[:error]).to eq("No active subscription found. Please contact us if you believe this is an error.")
        end
      end

      context "when there is no active subscription for the user" do
        before do
          customer = Stripe::Customer.create(email: user.email)
          user.update(stripe_id_code: customer.id)
        end

        it "does not cancel the subscription and shows an alert" do
          delete stripe_subscription_path("me"), params: { verification: "pleasecancelmyplusplus" }

          expect(response).to redirect_to(user_settings_path)
          expect(flash[:error]).to eq("No active subscription found.")
        end
      end
    end
  end
end
