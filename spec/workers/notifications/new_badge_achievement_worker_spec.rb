require "rails_helper"
RSpec.describe Notifications::NewBadgeAchievementWorker, type: :worker do
  describe "#perform" do
    let(:badge_achievement) { create(:badge_achievement) }
    let(:service) { Notifications::NewBadgeAchievement::Send }
    let(:worker) { subject }

    before do
      allow(service).to receive(:call)
    end

    it "calls a service" do
      worker.perform(badge_achievement.id)
      expect(service).to have_received(:call).with(badge_achievement).once
    end

    it "does nothing for non-existent badge achievement" do
      worker.perform(nil)
      expect(service).not_to have_received(:call)
    end
  end
end
