require "rails_helper"

RSpec.describe Users::NotificationSetting, type: :model do
  describe "validations" do
    subject { notification_setting }

    let(:user) { create(:user) }
    let(:notification_setting) { user.notification_setting }

    it { is_expected.to validate_inclusion_of(:email_digest_periodic).in_array(%w[true false]) }
  end
end
