require "rails_helper"

RSpec.describe Broadcast, type: :model do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:type_of) }
  it { is_expected.to validate_presence_of(:processed_html) }
  it { is_expected.to validate_inclusion_of(:type_of).in_array(%w[Announcement Welcome]) }

  it { is_expected.to have_many(:notifications) }

  it "validates that only one Broadcast with a type_of Announcement can be active" do
    create(:announcement_broadcast)

    inactive_broadcast = build(:announcement_broadcast)

    expect(inactive_broadcast).not_to be_valid
    expect(inactive_broadcast.errors.full_messages.join).to include("You can only have one active announcement broadcast")
  end
end
