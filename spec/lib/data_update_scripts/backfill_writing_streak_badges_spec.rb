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

    it "backfills historical streaks and finishes without error" do
      expect { described_class.new.run }.to change { user.reload.badges.pluck(:slug) }.to(["4-week-streak"])
    end
  end

  context "when a streak badge is missing" do
    before do
      create(:badge, title: "8 Week Streak", slug: "8-week-streak")
      create(:badge, title: "16 Week Streak", slug: "16-week-streak")
    end

    it "raises so the script is not recorded as succeeded" do
      expect { described_class.new.run }
        .to raise_error(described_class::MissingBadgesError, /4-week-streak/)
    end

    it "awards the skipped threshold when re-run after the badge is created" do
      expect { described_class.new.run }.to raise_error(described_class::MissingBadgesError)
      expect(user.reload.badges).to be_empty

      create(:badge, title: "4 Week Streak", slug: "4-week-streak")

      expect { described_class.new.run }.to change { user.reload.badges.count }.by(1)
    end
  end
end
