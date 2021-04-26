require "rails_helper"

RSpec.describe Badges::AwardYearlyClub, type: :service do
  describe ".call" do
    before do
      stub_const("#{described_class}::YEARS", described_class::YEARS.slice(1, 2, 3))
      allow(ApplicationConfig).to receive(:[])
      allow(Settings::Community).to receive(:copyright_start_year).and_return(3.years.ago.year)
      create(:badge, title: "one-year-club")
      create(:badge, title: "two-year-club")
      create(:badge, title: "three-year-club")
      create(:badge, title: "heysddssdhey")
    end

    it "awards birthday badge to birthday folks who registered a year ago" do
      user = create(:user, created_at: 366.days.ago)
      newer_user = create(:user, created_at: 6.days.ago)
      older_user = create(:user, created_at: 390.days.ago)

      described_class.call

      expect(user.badge_achievements.size).to eq(1)
      expect(newer_user.badge_achievements.size).to eq(0)
      expect(older_user.badge_achievements.size).to eq(0)
    end

    it "rewards 2-year birthday badge to birthday folks who registered 2 years ago" do
      user = create(:user, created_at: 731.days.ago)
      newer_user = create(:user, created_at: 6.days.ago)
      older_user = create(:user, created_at: 800.days.ago)

      described_class.call

      expect(user.badge_achievements.size).to eq(1)
      expect(newer_user.badge_achievements.size).to eq(0)
      expect(older_user.badge_achievements.size).to eq(0)
    end

    it "rewards 3-year birthday badge to birthday folks who registered 3 years ago" do
      user = create(:user, created_at: 1096.days.ago)
      newer_user = create(:user, created_at: 6.days.ago)
      older_user = create(:user, created_at: 1200.days.ago)

      described_class.call

      expect(user.badge_achievements.size).to eq(1)
      expect(newer_user.badge_achievements.size).to eq(0)
      expect(older_user.badge_achievements.size).to eq(0)
    end
  end
end
