require "rails_helper"

RSpec.describe "StripeActiveCards", type: :request do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:card_token) { stripe_helper.generate_card_token }

  before do
    StripeMock.start

    sign_in user
  end

  after { StripeMock.stop }

  def create_user_with_card(user, source)
    customer = Payments::Customer.create(
      email: "stripe_tester@dev.to",
      source: source,
    )
    user.update(stripe_id_code: customer.id)

    [customer, customer.sources.list.first]
  end

  describe "POST /stripe_active_cards" do
    it "successfully adds a card to the correct user" do
      post stripe_active_cards_path(stripe_token: stripe_helper.generate_card_token)
      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:settings_notice]).to eq("Your billing information has been updated")

      card = Payments::Customer.get(user.stripe_id_code).sources.first
      expect(card.is_a?(Stripe::Card)).to eq(true)
    end

    it "creates an AuditLog entry for successful creates" do
      expect do
        post stripe_active_cards_path(stripe_token: stripe_helper.generate_card_token)
      end.to change(AuditLog, :count).by(1)
    end

    it "does not add a card if there is a card error" do
      StripeMock.prepare_card_error(:incorrect_number, :create_source)

      post stripe_active_cards_path(stripe_token: stripe_helper.generate_card_token)

      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:error]).to be_present
      expect(Payments::Customer.get(user.stripe_id_code).sources.count).to eq(0)
    end

    it "increments sidekiq.errors in Datadog on failure" do
      allow(ForemStatsClient).to receive(:increment)
      invalid_error = Stripe::InvalidRequestError.new("message", "param")
      allow(Stripe::Customer).to receive(:create).and_raise(invalid_error)

      post stripe_active_cards_path(stripe_token: stripe_helper.generate_card_token)
      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:error]).to eq(invalid_error.message)

      tags = hash_including(tags: array_including("error:InvalidRequestError"))
      expect(ForemStatsClient).to have_received(:increment).with("stripe.errors", tags)
    end

    it "updates the user's updated_at" do
      old_updated_at = user.updated_at

      Timecop.freeze(1.minute.from_now) do
        post stripe_active_cards_path(stripe_token: stripe_helper.generate_card_token)
      end

      expect(user.reload.updated_at.to_i > old_updated_at.to_i).to be(true)
    end

    it "increments sidekiq.errors.new_subscription in Datadog on failure" do
      allow(ForemStatsClient).to receive(:increment)
      invalid_error = Stripe::InvalidRequestError.new(nil, nil)
      allow(Stripe::Customer).to receive(:create).and_raise(invalid_error)
      post "/stripe_active_cards", params: { stripe_token: stripe_helper.generate_card_token }

      tags = hash_including(tags: array_including("action:create_card", "user_id:#{user.id}"))
      expect(ForemStatsClient).to have_received(:increment).with("stripe.errors", tags)
    end
  end

  describe "PUT /stripe_active_cards/:card_id" do
    it "updates the customer default source" do
      customer, source = create_user_with_card(user, card_token)
      expect(customer.default_source).to eq(source.id)

      # add a second source
      new_card_token = stripe_helper.generate_card_token
      new_card = Payments::Customer.create_source(customer.id, new_card_token)

      put stripe_active_card_path(id: new_card.id)
      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:settings_notice]).to eq("Your billing information has been updated")

      expect(Payments::Customer.get(customer.id).default_source).to eq(new_card.id)
    end

    it "creates an AuditLog entry for successful updates" do
      customer, = create_user_with_card(user, card_token)
      # add a second source
      new_card_token = stripe_helper.generate_card_token
      new_card = Payments::Customer.create_source(customer.id, new_card_token)

      expect do
        put stripe_active_card_path(id: new_card.id)
      end.to change(AuditLog, :count).by(1)
    end

    it "does not update the customer default souce if the source ID is unknown" do
      customer, source = create_user_with_card(user, card_token)

      put stripe_active_card_path(id: "unknown")
      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:error]).to eq("There is no source with ID unknown")

      expect(Payments::Customer.get(customer.id).default_source).to eq(source.id)
    end

    it "increments sidekiq.errors in Datadog on failure" do
      _, source = create_user_with_card(user, card_token)
      original_card_id = source.id

      allow(ForemStatsClient).to receive(:increment)
      card_error = Stripe::CardError.new("message", "param")
      allow(Stripe::Customer).to receive(:retrieve).and_raise(card_error)

      put stripe_active_card_path(id: original_card_id)
      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:error]).to eq(card_error.message)

      tags = hash_including(tags: array_including("error:CardError"))
      expect(ForemStatsClient).to have_received(:increment).with("stripe.errors", tags)
    end

    it "updates the user's updated_at" do
      _, source = create_user_with_card(user, card_token)
      old_updated_at = user.updated_at

      Timecop.freeze(1.minute.from_now) do
        put stripe_active_card_path(id: source.id)
      end

      expect(user.reload.updated_at.to_i > old_updated_at.to_i).to be(true)
    end

    it "increments sidekiq.errors.update_subscription in Datadog on failure" do
      _, source = create_user_with_card(user, card_token)
      original_card_id = source.id

      allow(ForemStatsClient).to receive(:increment)
      card_error = Stripe::CardError.new("message", "param")
      allow(Stripe::Customer).to receive(:retrieve).and_raise(card_error)

      put stripe_active_card_path(id: original_card_id)
      expect(response).to redirect_to(user_settings_path(:billing))
      expect(flash[:error]).to eq(card_error.message)
      tags = hash_including(tags: array_including("action:update_card", "user_id:#{user.id}"))
      expect(ForemStatsClient).to have_received(:increment).with("stripe.errors", tags)
    end
  end

  describe "DELETE /stripe_active_cards/:card_id" do
    context "when a valid request is made" do
      before do
        _, source = create_user_with_card(user, card_token)
        original_card_id = source.id
        delete stripe_active_card_path(id: original_card_id)
      end

      it "redirects to billing page" do
        expect(response).to redirect_to(user_settings_path(:billing))
      end

      it "provides the proper flash notice" do
        expect(flash[:settings_notice]).to eq("Your card has been successfully removed.")
      end

      it "successfully deletes the card from sources" do
        customer = Payments::Customer.get(user.stripe_id_code)
        expect(Payments::Customer.get_sources(customer).count).to eq(0)
      end

      it "creates an AuditLog entry for successful deletes" do
        _, source = create_user_with_card(user, card_token)

        expect do
          delete stripe_active_card_path(id: source.id)
        end.to change(AuditLog, :count).by(1)
      end
    end

    context "when an invalid request is made" do
      it "redirects with an error if the card ID is unknown" do
        create_user_with_card(user, card_token)

        delete stripe_active_card_path(id: "unknown")
        expect(response).to redirect_to(user_settings_path(:billing))
        expect(flash[:error]).to eq("There is no source with ID unknown")
      end

      it "redirects with an error if the customer has a subscription" do
        customer, = create_user_with_card(user, card_token)

        product = stripe_helper.create_product
        plan = stripe_helper.create_plan(product: product.id)
        Stripe::Subscription.create(customer: customer.id, items: [{ plan: plan.id }])

        delete stripe_active_card_path(id: "unknown")
        expect(response).to redirect_to(user_settings_path(:billing))
        error = "Can't remove card if you have an active membership. Please cancel your membership first."
        expect(flash[:error]).to eq(error)
      end
    end

    it "updates the user's updated_at" do
      _, source = create_user_with_card(user, card_token)
      original_card_id = source.id

      old_updated_at = user.updated_at

      Timecop.freeze(1.minute.from_now) do
        delete stripe_active_card_path(id: original_card_id)
      end

      expect(user.reload.updated_at.to_i > old_updated_at.to_i).to be(true)
    end
  end
end
