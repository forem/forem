require "rails_helper"

RSpec.describe SubscriptionSource, type: :model do
  subject { build(:subscription_source) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:subscription_sourceable_id) }
    it { is_expected.to validate_presence_of(:subscription_sourceable_type) }
    it { is_expected.to validate_presence_of(:subscriber_id) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_inclusion_of(:subscription_sourceable_type).in_array(%w[Article]) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(:subscription_sourceable_type, :subscription_sourceable_id) }
  end
end
