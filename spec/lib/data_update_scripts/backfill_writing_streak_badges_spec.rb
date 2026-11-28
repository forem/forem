require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20261109120000_backfill_writing_streak_badges.rb",
)

RSpec.describe DataUpdateScripts::BackfillWritingStreakBadges do
  let(:user) { create(:user) }

  before do
    # A four week streak that ended long ago, which only a historical pass rewards.
    [100, 93, 86, 79].each do |days|
      create(:article, :past, user: user, published: true, past_published_at: days.days.ago)
    end
  end

  context "when every streak badge exists" do
    before do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak")
      create(:badge, title: "8 Week Streak", slug: "8-week-streak")
      create(:badge, title: "16 Week Streak", slug: "16-week-streak")
    end

    it "backfills historical streaks" do
      expect { described_class.new.run }.to change { user.reload.badges.pluck(:slug) }.to(["4-week-streak"])
    end
  end

  context "when no streak badges exist" do
    it "completes without raising and logs the missing slugs" do
      allow(Rails.logger).to receive(:info)

      expect { described_class.new.run }.not_to raise_error
      expect(Rails.logger).to have_received(:info).with(/Badge slugs not found: .*4-week-streak/)
      expect(user.reload.badges).to be_empty
    end

    it "is marked succeeded by DataUpdateWorker" do
      script = DataUpdateScript.create!(file_name: "20261109120000_backfill_writing_streak_badges")

      DataUpdateWorker.new.perform(script.id)

      expect(script.reload).to be_succeeded
    end
  end

  context "when some awards fail" do
    before do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak", credits_awarded: 5)
      allow(Rails.error).to receive(:report)
      allow(Credit).to receive(:add_to).and_raise(ActiveRecord::ConnectionTimeoutError, "simulated outage")
    end

    it "is marked failed by DataUpdateWorker so the backfill is not lost" do
      script = DataUpdateScript.create!(file_name: "20261109120000_backfill_writing_streak_badges")

      DataUpdateWorker.new.perform(script.id)

      expect(script.reload).to be_failed
      expect(script.error).to include("Badges::AwardStreak::IncompleteError")
    end
  end

  context "when only some streak badges exist" do
    before { create(:badge, title: "4 Week Streak", slug: "4-week-streak") }

    it "awards the configured thresholds and skips the rest" do
      expect { described_class.new.run }.not_to raise_error
      expect(user.reload.badges.pluck(:slug)).to eq(["4-week-streak"])
    end
  end
end
