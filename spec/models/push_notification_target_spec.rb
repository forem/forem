require "rails_helper"

RSpec.describe PushNotificationTarget, type: :model do
  let!(:pn_target) { create(:push_notification_target) }
  let!(:pn_target_disabled) { create(:push_notification_target, active: false) }

  it "fetches all the targets and ensures the forem app is included" do
    all_targets = described_class.all_targets

    # pn_target + the forem app in all SUPPORTED_FOREM_APP_PLATFORMS
    expect(all_targets.count).to eq(3)
  end

  describe "active?" do
    it "uses the active value in the DB for non-forem apps" do
      expect(pn_target.active?).to be true
      expect(pn_target_disabled.active?).to be false
    end

    it "returns true/false based on the ENV variable for the forem apps" do
      allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("asdf123")
      expect(described_class.forem_app(platform: Device::IOS).active?).to be true

      allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return(nil)
      expect(described_class.forem_app(platform: Device::IOS).active?).to be false
    end
  end
end
