require "rails_helper"

RSpec.describe UserSubscription, type: :model do
  subject { build(:user_subscription) }

  let(:source) { create(:article) }
  let(:subscriber) { create(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:user_subscription_sourceable_id) }
    it { is_expected.to validate_presence_of(:user_subscription_sourceable_type) }
    it { is_expected.to validate_presence_of(:subscriber_id) }
    it { is_expected.to validate_presence_of(:subscriber_email) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_inclusion_of(:user_subscription_sourceable_type).in_array(%w[Article]) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(%i[subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id]) }
  end

  describe "#build" do
    it "returns a new UserSubcription with the correct attributes" do
      new_user_subscription = described_class.new(
        user_subscription_sourceable: source,
        author_id: source.user_id,
        subscriber_id: subscriber.id,
        subscriber_email: subscriber.email,
      )

      factory_user_subscription = described_class.build(source: source, subscriber: subscriber)

      factory_user_subscription.attributes.each do |name, val|
        expect(new_user_subscription[name]).to eq val
      end
    end
  end

  describe "#make" do
    it "returns a created UserSubcription with the correct attributes" do
      user_subscription_fields = %w[author_id subsciber_id subscriber_email user_subscription_sourceable_id user_susbcription_sourceable_type]

      user_subscription = create(:user_subscription,
                                 user_subscription_sourceable: source,
                                 author_id: source.user_id,
                                 subscriber_id: subscriber.id,
                                 subscriber_email: subscriber.email)

      factory_user_subscription = described_class.make(source: source, subscriber: subscriber)

      user_subscription_fields.each do |field|
        expect(factory_user_subscription[field]).to eq user_subscription[field]
      end
    end
  end

  describe "counter_culture" do
    let(:user) { create(:user) }

    context "when a UserSubscription is created" do
      it "increments subscribed_to_user_subscriptions_count on user" do
        expect do
          create(:user_subscription, subscriber: user)
        end.to change { user.reload.subscribed_to_user_subscriptions_count }.by(1)
      end
    end

    context "when a UserSubscription is destroyed" do
      it "decrements subscribed_to_user_subscriptions_count on user" do
        user_subscription = create(:user_subscription, subscriber: user)
        expect do
          user_subscription.destroy
        end.to change { user.reload.subscribed_to_user_subscriptions_count }.by(-1)
      end
    end
  end
end
