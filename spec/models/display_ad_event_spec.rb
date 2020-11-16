require "rails_helper"

RSpec.describe DisplayAdEvent, type: :model do
  let(:user) { build(:user) }
  let(:organization) { build(:organization) }
  let(:display_ad) { build(:display_ad, organization: organization) }

  describe "#category" do
    it "is valid with a click category" do
      event = build(:display_ad_event, category: "click", user: user, display_ad: display_ad)
      expect(event).to be_valid
    end

    it "is valid with an impression category" do
      event = build(:display_ad_event, category: "impression", user: user, display_ad: display_ad)
      expect(event).to be_valid
    end

    it "is not valid with an uknown category" do
      event = build(:display_ad_event, category: "wazoo", user: user, display_ad: display_ad)
      expect(event).not_to be_valid
    end
  end
end
