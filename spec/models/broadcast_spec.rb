require "rails_helper"

RSpec.describe Broadcast, type: :model do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:type_of) }
  it { is_expected.to validate_presence_of(:processed_html) }
  it { is_expected.to validate_inclusion_of(:type_of).in_array(%w[Announcement Welcome]) }
  it { is_expected.to validate_inclusion_of(:banner_style).in_array(%w[default brand success warning error]) }
  it { is_expected.to validate_uniqueness_of(:title).scoped_to(:type_of) }

  it { is_expected.to have_many(:notifications) }

  it "validates that only one Broadcast with a type_of Announcement can be active" do
    create(:announcement_broadcast)

    inactive_broadcast = build(:announcement_broadcast)

    expect(inactive_broadcast).not_to be_valid
    expect(inactive_broadcast.errors.full_messages.join).to include("You can only have one active announcement broadcast")
  end

  it "determines the correct banner_class for the Broadcast" do
    no_style_broadcast = create(:announcement_broadcast, active: false)
    default_style_broadcast = create(:announcement_broadcast, title: "Default", banner_style: "default", active: false)
    warning_style_broadcast = create(:announcement_broadcast, title: "Warning", banner_style: "warning", active: false)

    expect(no_style_broadcast.banner_class).to eq(nil)
    expect(default_style_broadcast.banner_class).to eq("crayons-banner")
    expect(warning_style_broadcast.banner_class).to eq("crayons-banner crayons-banner--warning")
  end
end
