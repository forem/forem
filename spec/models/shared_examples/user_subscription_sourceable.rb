RSpec.shared_examples "UserSubscriptionSourceable" do
  let(:model) { described_class }
  let(:source) do
    create(model.to_s.underscore.to_sym, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
  end
  let(:subscriber) { create(:user) }

  describe "#build_user_subscription" do
    it "returns a new UserSubcription with the correct attributes" do
      new_user_subscription = UserSubscription.new(
        user_subscription_sourceable: source,
        author_id: source.user_id,
        subscriber_id: subscriber.id,
        subscriber_email: subscriber.email,
      )

      factory_user_subscription = source.build_user_subscription(subscriber)

      factory_user_subscription.attributes.each do |name, val|
        expect(new_user_subscription[name]).to eq val
      end
    end
  end

  describe "#create_user_subscription" do
    it "returns a created UserSubcription with the correct attributes" do
      user_subscription_fields = %w[author_id subsciber_id subscriber_email user_subscription_sourceable_id
                                    user_susbcription_sourceable_type]

      user_subscription = create(
        :user_subscription,
        user_subscription_sourceable: source,
        author_id: source.user_id,
        subscriber_id: subscriber.id,
        subscriber_email: subscriber.email,
      )

      factory_user_subscription = source.create_user_subscription(subscriber)

      user_subscription_fields.each do |field|
        expect(factory_user_subscription[field]).to eq user_subscription[field]
      end
    end
  end

  describe "counter_culture" do
    context "when a UserSubscription is created" do
      it "increments user_subscriptions_count" do
        expect do
          create(:user_subscription, user_subscription_sourceable: source)
        end.to change { source.reload.user_subscriptions_count }.by(1)
      end
    end

    context "when a UserSubscription is destroyed" do
      it "decrements user_subscriptions_count" do
        user_subscription = create(:user_subscription, user_subscription_sourceable: source)
        expect do
          user_subscription.destroy
        end.to change { source.reload.user_subscriptions_count }.by(-1)
      end
    end
  end
end
