require "rails_helper"

RSpec.describe BadgeAchievements::BadgeAwardWorker, type: :worker do
  let(:worker) { subject }

  # passing in a random badge_achievement_id argument since the worker itself won't be executed
  include_examples "#enqueues_on_correct_queue", "high_priority", [456]

  describe "#perform_now" do
    before do
      allow(Badges::Award).to receive(:call)
    end

    context "with badge achievement" do
      it "sends badge email" do
        relation = User.none
        allow(User).to receive(:where).with(username: ["jess"]).and_return(relation)
        worker.perform(["jess"], "test", "yo")

        expect(Badges::Award).to have_received(:call).with(relation, "test", "yo")
      end
    end

    context "with predefined badge_slug" do
      it "sends badge email" do
        allow(Badges::AwardYearlyClub).to receive(:call)
        worker.perform([], "award_yearly_club", "")

        expect(Badges::AwardYearlyClub).to have_received(:call)
        expect(Badges::Award).not_to have_received(:call)
      end
    end
  end
end
