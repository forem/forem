require "rails_helper"

RSpec.describe PushNotificationSubscription, type: :model do
  describe "validation" do
    subject do
      described_class.create(user: create(:user),
                             auth_key: "asdf123",
                             endpoint: "asdf123")
    end

    it { is_expected.to validate_presence_of(:endpoint) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:p256dh_key) }
    it { is_expected.to validate_presence_of(:auth_key) }
    it { is_expected.to validate_presence_of(:notification_type) }
    it { is_expected.to validate_uniqueness_of(:endpoint) }
    it { is_expected.to validate_uniqueness_of(:p256dh_key) }
    it { is_expected.to validate_uniqueness_of(:auth_key) }
    it { is_expected.to belong_to(:user) }
  end
end
