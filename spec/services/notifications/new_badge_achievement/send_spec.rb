require "rails_helper"

RSpec.describe Notifications::NewBadgeAchievement::Send, type: :service do
  let(:badge_achievement) { create(:badge_achievement) }

  def expected_json_data
    {
      user: Notifications.user_data(badge_achievement.user),
      badge_achievement: {
        badge_id: badge_achievement.badge_id,
        rewarding_context_message: badge_achievement.rewarding_context_message,
        badge: {
          title: badge_achievement.badge.title,
          description: badge_achievement.badge.description,
          badge_image_url: badge_achievement.badge.badge_image_url
        }
      }
    }.to_json
  end

  it "creates a notification" do
    expect do
      described_class.call(badge_achievement)
    end.to change(Notification, :count).by(1)
  end

  it "creates a notification for the badge achievement user" do
    described_class.call(badge_achievement)
    expect(Notification.last.user).to eq(badge_achievement.user)
  end

  it "creates a notification for the badge achievement" do
    described_class.call(badge_achievement)
    notification = Notification.find_by(
      notifiable_id: badge_achievement.id, notifiable_type: "BadgeAchievement",
    )
    expect(notification).not_to be(nil)
  end

  it "creates a notification with not action" do
    described_class.call(badge_achievement)
    expect(Notification.last.action).to be(nil)
  end

  it "creates a notification with the proper json data" do
    described_class.call(badge_achievement)
    json_data = Notification.last.json_data.to_json
    expect(JSON.parse(json_data)).to eq(JSON.parse(expected_json_data))
  end
end
