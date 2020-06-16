require "rails_helper"

RSpec.describe UserSubscription, type: :model do
  subject { build(:user_subscription) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:user_subscription_sourceable_id) }
    it { is_expected.to validate_presence_of(:user_subscription_sourceable_type) }
    it { is_expected.to validate_presence_of(:subscriber_id) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_inclusion_of(:user_subscription_sourceable_type).in_array(%w[Article]) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(:user_subscription_sourceable_type, :user_subscription_sourceable_id) }
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

    context "when a reaction is destroyed" do
      it "decrements subscribed_to_user_subscriptions_count on user" do
        user_subscription = create(:user_subscription, subscriber: user)
        expect do
          user_subscription.destroy
        end.to change { user.reload.subscribed_to_user_subscriptions_count }.by(-1)
      end
    end
  end
end
