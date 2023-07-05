require "rails_helper"

RSpec.describe "/api/admin/organizations" do
  let!(:org_params) { { name: "Test Org", summary: "a test org", url: "https://testorg.io", profile_image: Rails.root.join("app/assets/images/#{rand(1..40)}.png").open, slug: "test-org" } }
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  context "when unauthorized" do
    it "rejects requests without an authorization token" do
      expect do
        post api_admin_organizations_path, params: org_params, headers: v1_headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a non-admin token" do
      api_secret = create(:api_secret, user: create(:user))
      headers = v1_headers.merge({ "api-key" => api_secret.secret })

      expect do
        post api_admin_organizations_path, params: org_params, headers: headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a regular admin token" do
      api_secret = create(:api_secret, user: create(:user, :admin))
      headers = v1_headers.merge({ "api-key" => api_secret.secret })

      expect do
        post api_admin_organizations_path, params: org_params, headers: headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authorized" do
    let!(:super_admin) { create(:user, :super_admin) }
    let(:api_secret) { create(:api_secret, user: super_admin) }
    let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    context "when creating an organization" do
      it "accepts request with a super-admin token" do
        expect do
          post api_admin_organizations_path params: org_params, headers: headers
        end.to change(Organization, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when updating an organization" do
      let!(:organization) { create(:organization, org_params) }

      it "accepts request with a super-admin token" do
        expect do
          put api_admin_organization_path(organization.id), headers: headers, params: {
            organization: org_params.merge(summary: "new summary")
          }
        end.to change(Organization.first, :summary).to("new summary")

        expect(response).to have_http_status(:ok)
      end
    end

    context "when deleting an organization" do
      let!(:organization) { create(:organization, org_params) }

      it "accepts request with a super-admin token" do
        expect do
          delete api_admin_organization_path(organization.id), headers: headers
        end.to change(Organization, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
