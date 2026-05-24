require "rails_helper"

RSpec.describe "Organization Lead Forms Backend Protection" do
  let(:admin_user) { create(:user, :org_admin) }
  let(:organization) { admin_user.organizations.first }

  before do
    sign_in admin_user
  end

  describe "GET /:slug/settings/lead-forms" do
    context "when feature flag is disabled" do
      before { FeatureFlag.disable(:org_lead_forms) }

      it "returns 404 Not Found" do
        expect do
          get organization_lead_forms_path(organization.slug)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when feature flag is enabled" do
      before { FeatureFlag.enable(:org_lead_forms, FeatureFlag::Actor[organization]) }

      it "returns 200 OK" do
        get organization_lead_forms_path(organization.slug)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /:slug/settings/lead-forms" do
    context "when feature flag is disabled" do
      before { FeatureFlag.disable(:org_lead_forms) }

      it "returns 404 Not Found" do
        expect do
          post organization_lead_forms_path(organization.slug), params: { organization_lead_form: { title: "Test", button_text: "Submit" } }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
