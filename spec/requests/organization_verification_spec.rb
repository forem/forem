require "rails_helper"

RSpec.describe "Organization Verification Backend Protection" do
  let(:admin_user) { create(:user, :org_admin) }
  let(:organization) do
    org = admin_user.organizations.first
    org.update!(url: "https://example.com")
    org
  end

  before do
    sign_in admin_user
  end

  describe "POST /:slug/request_verification" do
    context "when feature flag is disabled" do
      before { FeatureFlag.disable(:org_verification) }

      it "returns 404 Not Found" do
        expect do
          post organization_request_verification_path(organization.slug), params: { verification_url: "https://example.com" }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when feature flag is enabled" do
      before { FeatureFlag.enable(:org_verification, FeatureFlag::Actor[organization]) }

      it "redirects properly" do
        post organization_request_verification_path(organization.slug), params: { verification_url: "https://example.com" }
        expect(response).to redirect_to(organization_settings_path(organization.slug, anchor: "section-verification"))
      end
    end
  end
end
