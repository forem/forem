require "rails_helper"

RSpec.describe "StripeSubscriptions", type: :request do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_source_token) { stripe_helper.generate_card_token }

  before do
    StripeMock.start
    sign_in user
  end

  after { StripeMock.stop }

  def valid_instance(user = user_one, amount = 1200)
    customer = Stripe::Customer.create(
      email: "stripe_tester@dev.to",
      source: stripe_helper.generate_card_token,
    )
    user.update(stripe_id_code: customer.id)
    MembershipService.new(Stripe::Customer.retrieve(user.stripe_id_code), user, amount)
  end


  describe "POST StripeActiveCards#create" do
    it "successfully adds a card to the correct user" do
      post "/stripe_active_cards", params: { stripe_token: stripe_helper.generate_card_token }
      card = Stripe::Customer.retrieve(user.stripe_id_code).sources.first
      expect(card.is_a?(Stripe::Card)).to eq(true)
    end
  end

  describe "PATCH StripeActiveCards#update" do
    before do
      post "/stripe_subscriptions", params: { amount: "12",
                                              stripe_token: stripe_helper.generate_card_token }
    end

    it "properly updates the default card" do
      first_card = Stripe::Customer.retrieve(user.stripe_id_code).sources.first
      put "/stripe_active_cards/#{first_card.id}"
      source = Stripe::Customer.retrieve(user.stripe_id_code).default_source
      expect(source).to eq(first_card.id)
    end
  end

  describe "DESTROY StripeActiveCards#destroy" do
    context "when a valid request is made" do
      before do
        valid_instance(user)
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        original_card_id = customer.sources.all(object: "card").first.id
        delete "/stripe_active_cards/#{original_card_id}"
      end

      it "redirects to billing page" do
        expect(response).to redirect_to("/settings/billing")
      end

      it "provides the proper flash notice" do
        expect(flash[:notice]).to eq("Your card has been successfully removed.")
      end

      it "successfully deletes the card" do
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        expect(customer.sources.all.count).to eq(0)
      end
    end

    context "when a user only has one card and one subscription" do
      before do
        valid_instance(user)
        post "/stripe_subscriptions", params: { amount: 12 }
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        original_card_id = customer.sources.all(object: "card").first.id
        delete "/stripe_active_cards/#{original_card_id}"
      end

      it "provides the proper flash error" do
        expect(flash[:error]).to include("Can't remove card if you have an active membership.")
      end

      it "redirects to billing page" do
        expect(response).to redirect_to("/settings/billing")
      end

      it "does not delete the card" do
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        expect(customer.sources.all.count).to eq(1)
      end
    end
  end
end
