require "rails_helper"

RSpec.describe Users::ConvertPageviewFieldTestGoalsWorker, type: :worker do
  include FieldTest::Helpers

  include_examples "#enqueues_on_correct_queue", "low_priority", "some_experiment"

  describe "#perform" do
    let(:experiment) { "segmented_feed_configs_20260904" }
    let(:two_days_goal) { "user_views_pages_on_at_least_two_different_days_within_a_week" }
    let(:four_days_goal) { "user_views_pages_on_at_least_four_different_days_within_a_week" }
    let(:user) { create(:user, last_presence_at: 1.hour.ago) }
    let(:membership) { FieldTest::Membership.find_by(experiment: experiment, participant_id: user.id.to_s) }

    before do
      config = FieldTest.config.deep_dup
      config["experiments"][experiment] = {
        "started_at" => 30.days.ago.to_date,
        "variants" => %w[control segmented],
        "weights" => [50, 50],
        "goals" => ["user_creates_comment", two_days_goal, four_days_goal]
      }
      allow(FieldTest).to receive(:config).and_return(config)

      field_test(experiment, participant: user)
      create(:page_view, user: user, created_at: 1.day.ago)
      create(:page_view, user: user, created_at: 2.days.ago)
    end

    it "converts the satisfied day-count goals once, even when run repeatedly" do
      described_class.new.perform(experiment)
      described_class.new.perform(experiment)

      expect(membership.events.pluck(:name)).to eq([two_days_goal])
    end

    it "skips participants who have not been present recently" do
      user.update_column(:last_presence_at, 20.days.ago)

      described_class.new.perform(experiment)

      expect(membership.events).to be_empty
    end

    it "does nothing for an unknown experiment" do
      expect { described_class.new.perform("nope") }.not_to change(FieldTest::Event, :count)
    end
  end
end
