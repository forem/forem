require "rails_helper"

RSpec.describe "/admin/content_manager/organizations org features" do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  before do
    sign_in(admin)
    FeatureFlag.add(:org_readme)
    FeatureFlag.add(:org_lead_forms)
    FeatureFlag.add(:org_verification)
  end

  after do
    FeatureFlag.disable(:org_readme)
    FeatureFlag.disable(:org_lead_forms)
    FeatureFlag.disable(:org_verification)
  end

  describe "PATCH /admin/organizations/:id/update_org_feature" do
    it "enables org_readme for an organization" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])).to be(true)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables org_readme for an organization" do
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])).to be(false)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end

    it "enables org_lead_forms for an organization" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[organization])).to be(true)
    end

    it "disables org_lead_forms for an organization" do
      FeatureFlag.enable(:org_lead_forms, FeatureFlag::Actor[organization])

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[organization])).to be(false)
    end

    it "creates a note when toggling a feature" do
      expect do
        patch update_org_feature_admin_organization_path(organization),
              params: { feature: "org_readme", enabled: "true" }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.noteable).to eq(organization)
      expect(note.author).to eq(admin)
      expect(note.content).to include("org_readme")
    end

    it "enables org_verification for an organization" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_verification", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_verification, FeatureFlag::Actor[organization])).to be(true)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables org_verification for an organization" do
      FeatureFlag.enable(:org_verification, FeatureFlag::Actor[organization])

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_verification", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_verification, FeatureFlag::Actor[organization])).to be(false)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end

    it "rejects unknown feature names" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_evil_feature", enabled: "true" }

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:error]).to be_present
    end
  end
end
