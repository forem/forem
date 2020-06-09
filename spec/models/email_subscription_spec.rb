require "rails_helper"

RSpec.describe EmailSubscription, type: :model do
  subject { build(:email_subscription) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email_subscribable_id) }
    it { is_expected.to validate_presence_of(:email_subscribable_type) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_inclusion_of(:email_subscribable_type).in_array(%w[Article]) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:email_subscribable_type, :email_subscribable_id) }
  end
end
