require "rails_helper"

RSpec.describe Badges::Award, type: :service do
  describe ".call" do
    let!(:badge) { create(:badge, title: "one-year-club") }
    let!(:user) { create(:user) }
    let!(:user2) { create(:user) }

    it "awards badges" do
      expect do
        described_class.call(User.all, "one-year-club", "Congrats on a badge!")
      end.to change(BadgeAchievement, :count).by(2)
    end

    it "creates correct badge achievements" do
      described_class.call(User.all, "one-year-club", "Congrats on a badge!")
      expect(user.badge_achievements.pluck(:badge_id)).to eq([badge.id])
      expect(user2.badge_achievements.pluck(:rewarding_context_message_markdown))
        .to eq(["Congrats on a badge!"])
    end
  end
end
