require "rails_helper"

RSpec.describe DisplayAdEvent, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:display_ad) { create(:display_ad, organization_id: organization.id) }

  it "creates a click event" do
    event = build(:display_ad_event, category: "click", user_id: user.id, display_ad_id: display_ad.id)
    expect(event).to be_valid
  end
  it "creates an impression event" do
    event = build(:display_ad_event, category: "impression", user_id: user.id, display_ad_id: display_ad.id)
    expect(event).to be_valid
  end

  it "does not create an invalid event" do
    event = build(:display_ad_event, category: "wazoo", user_id: user.id, display_ad_id: display_ad.id)
    expect(event).not_to be_valid
  end
end
