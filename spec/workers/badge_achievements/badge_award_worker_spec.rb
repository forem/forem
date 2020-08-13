require "rails_helper"

RSpec.describe BadgeAchievements::BadgeAwardWorker, type: :worker do
  let(:worker) { subject }
  let(:badge_rewarder) { BadgeRewarder }

  # passing in a random badge_achievement_id argument since the worker itself won't be executed
  include_examples "#enqueues_on_correct_queue", "high_priority", [456]

  describe "#perform_now" do
    before do
      allow(badge_rewarder).to receive(:award_badges)
    end

    context "with badge achievement" do
      it "sends badge email" do
        worker.perform("jess", "test", "yo")

        expect(badge_rewarder).to have_received(:award_badges).with("jess", "test", "yo")
      end
    end
  end
end
