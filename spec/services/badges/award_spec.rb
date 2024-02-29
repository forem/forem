require "rails_helper"

RSpec.describe Badges::Award, type: :service do
  describe ".call" do
    let!(:badge) { create(:badge, title: "one-year-club") }
    let!(:user) { create(:user) }
    let!(:user2) { create(:user) }

    it "awards badges" do
      expect do
        described_class.call(User.all, "one-year-club", "Congrats on a badge!", include_default_description: true)
      end.to change(BadgeAchievement, :count).by(2)
    end

    it "creates correct badge achievements" do
      described_class.call(User.all, "one-year-club", "Congrats on a badge!", include_default_description: true)
      expect(user.badge_achievements.pluck(:badge_id)).to eq([badge.id])
      expect(user2.badge_achievements.pluck(:rewarding_context_message_markdown))
        .to eq(["Congrats on a badge!"])
    end

    it "creates correct badge achievements without default description" do
      described_class.call(User.all, "one-year-club", "Congrats on a badge!", include_default_description: false)
      expect(user.badge_achievements.pluck(:include_default_description)).to eq([false])
    end

    it "creates correct badge achievements with default description" do
      described_class.call(User.all, "one-year-club", "Congrats on a badge!", include_default_description: true)
      expect(user.badge_achievements.pluck(:include_default_description)).to eq([true])
    end

    it "doesn't award badges to spam accounts" do
      spammer = create(:user, username: "spam_account")

      described_class.call(User.all, "one-year-club", "Congrats on a badge!", include_default_description: true)
      expect(user.badge_achievements.any?).to be true
      expect(spammer.badge_achievements.any?).to be false
    end
  end
end
