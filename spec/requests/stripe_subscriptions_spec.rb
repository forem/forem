require "rails_helper"

RSpec.describe "StripeSubscriptions", type: :request do
  let(:user) { create(:user, :super_admin) }
  let(:mock_instance) { instance_double(MembershipService) }
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    StripeMock.start
    sign_in user
  end

  after { StripeMock.stop }

  describe "POST StripeSubscriptions#create" do
    context "when a valid request is made" do
      # Amount is a string here because Stripe returns a string when form is submitted
      before do
        post "/stripe_subscriptions", params: {
          amount: "12",
          stripe_token: stripe_helper.generate_card_token,
        }
      end

      it "creates a customer in Stripe and assigns it to the correct user" do
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        expect(customer.is_a?(Stripe::Customer)).to eq(true)
      end

      it "assigns the proper role based on the amount" do
        expect(user.roles.last.name).to eq("level_2_member")
      end

      it "updates the user's monthly_dues with the proper amount" do
        expect(user.monthly_dues).to eq(1200)
      end

      it "redirects to /settings/membership" do
        expect(response.body).to include("Thank you so much")
      end
    end

    it "can't accept anything less than $1" do
      post "/stripe_subscriptions", params: {
        amount: rand(100) / 100,
        stripe_token: stripe_helper.generate_card_token,
      }
      expect(response).to redirect_to("/membership")
      user.reload
      expect(user.stripe_id_code).to eq(nil)
      expect(user.roles.count).to eq(1)
    end

    # only one type of invalid request right now
    context "when an invalid request is made" do
      it "redirects to /enter if there's no current_user" do
        sign_out user
        post "/stripe_subscriptions", params: { amount: "1" }
        expect(response).to redirect_to("/enter")
      end

      it "errors if amount is less than 0" do
        post "/stripe_subscriptions", params: { amount: "-1" }
        expect(response).to redirect_to("/membership")
      end

      it "errors if amount is 0" do
        post "/stripe_subscriptions", params: { amount: "0" }
        expect(response).to redirect_to("/membership")
      end

      it "denies requests without credit card" do
        post "/stripe_subscriptions", params: { amount: "25" }
        expect(response).to redirect_to("/membership")
        # user.reload
        # expect(user.stripe_id_code).to be(nil)
      end
    end

    it "handles errors if MembershipService#subscribe_customer fails" do
      allow(MembershipService).to receive(:new).and_return(mock_instance)
      allow(mock_instance).to receive(:subscribe_customer).and_return(nil)
      post "/stripe_subscriptions", params: { amount: "1" }
      expect(response).to redirect_to("/membership")
    end
  end

  describe "PUT StripeSubscriptions#update" do
    before do
      user.add_role(:level_2_member)
    end

    context "when there's a subscription for update" do
      before do
        post "/stripe_subscriptions", params: {
          amount: "12",
          stripe_token: stripe_helper.generate_card_token,
        }
      end

      it "assigns the proper role with a new subscription" do
        put "/stripe_subscriptions/current_user", params: {
          amount: "30",
          stripe_token: stripe_helper.generate_card_token,
        }
        expect(user.has_role?("level_4_member")).to eq(true)
      end

      it "updates the user's monthly_dues with the proper amount" do
        put "/stripe_subscriptions/current_user", params: {
          amount: "30",
          stripe_token: stripe_helper.generate_card_token,
        }
        user.reload
        expect(user.monthly_dues).to eq(3000)
      end

      it "handles errors if MembershipService#update_subscription fails" do
        allow(MembershipService).to receive(:new).and_return(mock_instance)
        allow(mock_instance).to receive(:update_subscription).and_return(nil)
        put "/stripe_subscriptions/current_user", params: {
          amount: "30",
          stripe_token: stripe_helper.generate_card_token,
        }
        expect(response).to redirect_to("/settings/membership")
      end

      it "can't accept anything less than $1" do
        put "/stripe_subscriptions/current_user", params: { amount: rand(100) / 100 }
        expect(response).to redirect_to("/settings/billing")
        user.reload
        expect(user.stripe_id_code).not_to eq(nil)
        expect(user.has_role?(:level_1_member)).to eq(false)
      end

    end
  end

  describe "DESTROY StripeSubscriptions#destroy" do
    before do
      user.add_role(:level_2_member)
      post "/stripe_subscriptions", params: {
        amount: "12",
        stripe_token: stripe_helper.generate_card_token,
      }
    end

    context "when a valid request is made" do
      it "deletes membership" do
        delete "/stripe_subscriptions/current_user", params: {
          stripe_token: stripe_helper.generate_card_token,
        }
        expect(user.has_role?("level_2_member")).to eq(false)
      end

      it "returns user monthly dues to zero" do
        delete "/stripe_subscriptions/current_user", params: {
          stripe_token: stripe_helper.generate_card_token,
        }
        user.reload
        expect(user.monthly_dues).to eq(0)
      end

      it "handles errors if MembershipService#unsubscribe_customer fails" do
        allow(MembershipService).to receive(:new).and_return(mock_instance)
        allow(mock_instance).to receive(:unsubscribe_customer).and_return(nil)
        delete "/stripe_subscriptions/current_user"
        expect(response).to redirect_to("/settings")
      end
    end
  end
end
