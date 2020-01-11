require "rails_helper"

RSpec.describe BadgeAchievement, type: :model do
  let_it_be(:achievement) { create(:badge_achievement) }

  describe "validations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:badge) }
    it { is_expected.to belong_to(:rewarder).class_name("User").optional }
    it { is_expected.to validate_uniqueness_of(:badge_id).scoped_to(:user_id) }
  end

  it "turns rewarding_context_message_markdown into rewarding_context_message HTML" do
    expect(achievement.rewarding_context_message).to include("</a>")
  end

  it "awards credits after create" do
    expect(achievement.user.credits.size).to eq(5)
  end

  it "notifies recipients after commit" do
    allow(Notification).to receive(:send_new_badge_achievement_notification)
    achievement.run_callbacks(:commit)
    expect(Notification).to have_received(:send_new_badge_achievement_notification).with(achievement)
  end
end
