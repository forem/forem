require "rails_helper"

RSpec.describe PushNotificationTarget, type: :model do
  let!(:pn_target) { create(:push_notification_target, platform: Device::IOS) }

  it "fetches all the targets and ensures the forem app is included" do
    all_targets = described_class.all_targets

    # pn_target + the forem apps in every FOREM_APP_PLATFORMS
    expect(all_targets.count).to eq(2)
  end

  describe "active?" do
    context "with non-forem apps" do
      it "returns false if not active in DB or credentials are unavailable" do
        inactive_pn_target = create(:push_notification_target, active: false)
        expect(inactive_pn_target.active?).to be false

        pn_target_without_credentials = create(:push_notification_target, auth_key: nil)
        expect(pn_target_without_credentials.active?).to be false
      end

      it "returns true if both active && credentials are available" do
        expect(pn_target.active?).to be true
      end
    end

    context "with forem apps" do
      it "returns true/false based on the ENV variable for the forem apps" do
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("asdf123")
        expect(described_class.forem_app_target(platform: Device::IOS).active?).to be true

        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return(nil)
        expect(described_class.forem_app_target(platform: Device::IOS).active?).to be false
      end
    end
  end

  describe "Redis-backed rpush app" do
    it "is recreated after updating a PushNotificationTarget" do
      # Fetch rpush app associated to the target
      rpush_app = described_class.rpush_app(
        app_bundle: pn_target.app_bundle,
        platform: pn_target.platform,
      )

      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.name).to eq(pn_target.app_bundle)

      # Modify the PushNotificationTarget
      pn_target.app_bundle = "new.app.bundle"
      expect(pn_target.save).to be true

      # Fetch rpush app again with new values
      rpush_app = described_class.rpush_app(
        app_bundle: pn_target.app_bundle,
        platform: pn_target.platform,
      )

      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.name).to eq(pn_target.app_bundle)
    end
  end
end
