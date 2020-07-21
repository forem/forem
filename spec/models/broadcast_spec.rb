require "rails_helper"

RSpec.describe Broadcast, type: :model do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:broadcastable_type) }
  it { is_expected.to validate_presence_of(:broadcastable_id) }
  it { is_expected.to validate_presence_of(:processed_html) }
  it { is_expected.to validate_inclusion_of(:broadcastable_type).in_array(%w[Announcement WelcomeNotification]) }
  it { is_expected.to validate_uniqueness_of(:title).scoped_to(:broadcastable_type) }

  it "validates that only one Broadcast with a broadcastable_type of Announcement can be active" do
    create(:announcement_broadcast)

    inactive_broadcast = build(:announcement_broadcast)

    expect(inactive_broadcast).not_to be_valid
    expected_error_message = "You can only have one active announcement broadcast"
    expect(inactive_broadcast.errors.full_messages.join).to include(expected_error_message)
  end

  it "updates the Broadcast's active_status_updated_at timestamp" do
    Timecop.freeze(Time.current) do
      current_time = Time.zone.now
      broadcast = create(:welcome_broadcast, active: false)
      expect(broadcast.active_status_updated_at).to eq(2.days.ago)
      broadcast.update(active: true)
      expect(broadcast.active_status_updated_at).to eq current_time
    end
  end
end
