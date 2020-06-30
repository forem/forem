require "rails_helper"

RSpec.describe UserSubscription, type: :model do
  subject { build(:user_subscription) }

  # TODO: (Alex Smith) - update roles before release
  let(:author) { create(:user, :super_admin) }
  let(:subscriber) { create(:user) }
  let(:source) { create(:article, user: author, body_markdown: "---\ntitle: User Subscription#{rand(1000)}\npublished: true\n---\n\n{% user_subscription 'CTA text' %}") }

  describe "validations" do
    it { is_expected.to validate_presence_of(:user_subscription_sourceable_id) }
    it { is_expected.to validate_presence_of(:user_subscription_sourceable_type) }
    it { is_expected.to validate_presence_of(:subscriber_id) }
    it { is_expected.to validate_presence_of(:subscriber_email) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_inclusion_of(:user_subscription_sourceable_type).in_array(["Article"]) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(%i[subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id]) }

    it "validates the source is active" do
      unpublished_source = create(:article, user: author, body_markdown: "---\ntitle: User Subscription#{rand(1000)}\npublished: false\n---\n\n{% user_subscription 'CTA text' %}")
      user_subscription = described_class.build(source: unpublished_source, subscriber: subscriber)
      expect(user_subscription).not_to be_valid
      expect(user_subscription.errors[:base]).to include "Inactive source."
    end

    it "validates the tag is enabled in the source" do
      source_without_tag = create(:article, user: author, body_markdown: "---\ntitle: User Subscription#{rand(1000)}\npublished: false\n---\n\n{% user #{author.username} %}")
      user_subscription = described_class.build(source: source_without_tag, subscriber: subscriber)
      expect(user_subscription).not_to be_valid
      expect(user_subscription.errors[:base]).to include "User subscriptions are not enabled for the source."
    end

    it "validates the subscriber isn't using an Apple private relay" do
      subscriber_with_apple_relay = create(:user, email: "test@privaterelay.appleid.com")
      user_subscription = described_class.build(source: source, subscriber: subscriber_with_apple_relay)
      expect(user_subscription).not_to be_valid
      expect(user_subscription.errors[:subscriber_email]).to include "Can't subscribe with an Apple private relay. Please update email."
    end

    # TODO: [@thepracticaldev/delightful]: re-enable this once email confirmation is re-enabled
    xit "validates the subscriber's email address is current" do
      user_subscription = described_class.new(user_subscription_sourceable: source, author: author, subscriber_id: subscriber.id, subscriber_email: "#{subscriber.email}-stale")
      expect(user_subscription).not_to be_valid
      expect(user_subscription.errors[:subscriber_email]).to include "Subscriber email mismatch."
    end
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
      factory_user_subscription = described_class.make(source: source, subscriber: subscriber)

      expect(factory_user_subscription.user_subscription_sourceable).to eq source
      expect(factory_user_subscription.author_id).to eq source.user_id
      expect(factory_user_subscription.subscriber_id).to eq subscriber.id
      expect(factory_user_subscription.subscriber_email).to eq subscriber.email
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
