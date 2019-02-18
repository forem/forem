require "rails_helper"

RSpec.describe ModerationService do
  let(:mod) { create(:user, :trusted) }
  let(:article) { create(:user) }

  describe "#send_moderation_notification" do
    it "sends Notification to a moderator" do
      mod
      allow(Notification).to receive(:create)
      run_background_jobs_immediately do
        described_class.new.send_moderation_notification(article)
      end
      expect(Notification).to have_received(:create).exactly(:once)
    end
  end
end
