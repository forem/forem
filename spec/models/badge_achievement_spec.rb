require "rails_helper"

RSpec.describe BadgeAchievement, type: :model do
  describe "validations" do
    subject { create(:badge_achievement) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:badge) }
    it { is_expected.to belong_to(:rewarder).class_name("User").optional }
    it { is_expected.to validate_uniqueness_of(:badge_id).scoped_to(:user_id) }
  end

  it "turns rewarding_context_message_markdown into rewarding_context_message HTML" do
    achievement = create(:badge_achievement)
    expect(achievement.rewarding_context_message).to include("</a>")
  end

  it "awards credits after create" do
    achievement = create(:badge_achievement)
    expect(achievement.user.credits.size).to eq(5)
  end
end
