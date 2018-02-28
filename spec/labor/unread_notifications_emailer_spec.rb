require "rails_helper"

RSpec.describe UnreadNotificationsEmailer, vcr: {} do
  let(:user) { create(:user) }

  it "returns boolean on whether or not to send an email based on user activity" do
    VCR.use_cassette("unread_notification_mailer", match_requests_on: [:method]) do
      expect(described_class.new(user).should_send_email?).to be_in([true, false])
    end
  end
end
