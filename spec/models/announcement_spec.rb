require "rails_helper"

RSpec.describe Announcement, type: :model do
  it { is_expected.to validate_inclusion_of(:banner_style).in_array(%w[default brand success warning error]) }
  it { is_expected.to have_one(:broadcast) }

  it "validates that only one Broadcast with a type_of Announcement can be active" do
    create(:announcement_broadcast)

    inactive_broadcast = build(:announcement_broadcast)

    expect(inactive_broadcast).not_to be_valid
    expect(inactive_broadcast.errors.full_messages.join).to include("You can only have one active announcement broadcast")
  end
end
