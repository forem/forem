require "rails_helper"

RSpec.describe Notifications::NewBadgeAchievementJob, type: :job do
  include_examples "#enqueues_job", "send_new_badge_achievement_notification", 5

  describe "#perform_now" do
    let(:new_badge_service) { double }

    before do
      allow(new_badge_service).to receive(:call)
    end

    it "calls the service" do
      badge_achievement = create(:badge_achievement)
      described_class.perform_now(badge_achievement.id, new_badge_service)
      expect(new_badge_service).to have_received(:call).with(badge_achievement).once
    end

    it "doesn't call a service if a nonexistent badge achievement is passed" do
      described_class.perform_now(9999, new_badge_service)
      expect(new_badge_service).not_to have_received(:call)
    end
  end
end
