require "rails_helper"

RSpec.describe "/admin/customization/org_features" do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
    FeatureFlag.add(:org_readme)
    FeatureFlag.add(:org_lead_forms)
  end

  after do
    FeatureFlag.disable(:org_readme)
    FeatureFlag.disable(:org_lead_forms)
  end

  describe "GET /admin/customization/org_features" do
    it "renders the org features page" do
      get admin_org_features_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Readme Page")
      expect(response.body).to include("Lead Forms")
    end

    it "shows orgs with individual feature access" do
      org = create(:organization, name: "Test Corp")
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[org])

      get admin_org_features_path
      expect(response.body).to include("Test Corp")
    end
  end

  describe "PATCH /admin/customization/org_features/toggle_global" do
    it "enables a feature globally" do
      patch toggle_global_admin_org_features_path, params: { feature: "org_readme", enabled: "true" }

      expect(Flipper.feature(:org_readme).state).to eq(:on)
      expect(response).to redirect_to(admin_org_features_path)
      expect(flash[:notice]).to include("enabled")
    end

    it "disables a feature globally" do
      FeatureFlag.enable(:org_readme)

      patch toggle_global_admin_org_features_path, params: { feature: "org_readme", enabled: "false" }

      expect(Flipper.feature(:org_readme).state).not_to eq(:on)
      expect(response).to redirect_to(admin_org_features_path)
    end

    it "rejects unknown features" do
      patch toggle_global_admin_org_features_path, params: { feature: "org_evil", enabled: "true" }

      expect(response).to redirect_to(admin_org_features_path)
      expect(flash[:error]).to be_present
    end
  end

  describe "PATCH /admin/customization/org_features/update_cta" do
    it "updates CTA settings" do
      patch update_cta_admin_org_features_path, params: {
        cta_text: "Contact sales for premium access",
        cta_url: "https://example.com/contact"
      }

      expect(Settings::General.org_features_cta_text).to eq("Contact sales for premium access")
      expect(Settings::General.org_features_cta_url).to eq("https://example.com/contact")
      expect(response).to redirect_to(admin_org_features_path)
    end
  end
end
