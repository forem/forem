require "rails_helper"

RSpec.describe Users::SelectModeratorsQuery, type: :query do
  # last_reacted_at is within the bounds, and last_moderation_notification is within the bounds
  let(:user1) do
    create(:user, :trusted,
           last_moderation_notification: 4.days.ago,
           last_reacted_at: 1.day.ago)
  end

  # last_reacted_at is not within the bounds, and last_moderation_notification is not within the bounds
  let(:user2) do
    create(:user, :trusted,
           last_moderation_notification: 2.days.ago,
           last_reacted_at: 8.days.ago)
  end

  # last_reacted_at is within the bounds, and last_moderation_notification is not within the bounds
  let(:user3) do
    create(:user, :trusted,
           last_moderation_notification: 2.days.ago,
           last_reacted_at: 2.days.ago)
  end

  # user is not trusted
  let(:user4) { create(:user, last_reacted_at: 2.days.ago) }

  before do
    user1.notification_setting.update(mod_roundrobin_notifications: true)
    user2.notification_setting.update(mod_roundrobin_notifications: true)
    user3.notification_setting.update(mod_roundrobin_notifications: true)
  end

  it "returns an accurate list of available moderators" do
    expect(described_class.call).to include(user1)
    expect(described_class.call).not_to include(user2, user3, user4)
  end

  it "returns an empty array when there are no moderators that meet the criteria" do
    user1.notification_setting.update(mod_roundrobin_notifications: false)

    expect(described_class.call).to eq([])
  end
end
