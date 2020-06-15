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
end
