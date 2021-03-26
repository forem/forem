require "rails_helper"

RSpec.describe BadgeAchievement, type: :model do
  let(:badge_with_credits) { create(:badge, credits_awarded: 10) }
  let(:badge) { create(:badge, credits_awarded: 0) }
  let(:achievement) { create(:badge_achievement, badge: badge) }
  let(:credits_achievement) { create(:badge_achievement, badge: badge_with_credits) }

  describe "validations" do
    describe "builtin validations" do
      subject { achievement }

      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:badge) }
      it { is_expected.to belong_to(:rewarder).class_name("User").optional }
      it { is_expected.to validate_uniqueness_of(:badge_id).scoped_to(:user_id) }
    end
  end

  it "turns rewarding_context_message_markdown into rewarding_context_message HTML" do
    expect(achievement.rewarding_context_message).to include("</a>")
  end

  it "doesn't award credits if credits_awarded is zero" do
    expect(achievement.user.credits.size).to eq(0)
  end

  it "awards credits after create if credits_awarded exist" do
    expect(credits_achievement.user.credits.size).to eq(10)
  end

  it "notifies recipients after commit" do
    achievement
    allow(Notification).to receive(:send_new_badge_achievement_notification)
    achievement.run_callbacks(:commit)
    expect(Notification).to have_received(:send_new_badge_achievement_notification).with(achievement)
  end
end
