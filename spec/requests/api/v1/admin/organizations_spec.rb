require "rails_helper"

RSpec.describe "/api/admin/organizations" do
  let(:image) { Rails.root.join("app/assets/images/#{rand(1..40)}.png").open }
  let!(:org_params) do
    {
      name: "Test Org",
      summary: "a test org",
      url: "https://testorg.io",
      profile_image: image,
      slug: "test-org",
      tag_line: "a tagline"
    }
  end
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

  context "when authorized as super-admin" do
    let!(:super_admin) { create(:user, :super_admin) }
    let(:api_secret) { create(:api_secret, user: super_admin) }
    let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    context "when creating an organization" do
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "accepts request and creates the organization with valid params" do
        expect do
          post api_admin_organizations_path, params: org_params, headers: headers
        end.to change(Organization, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it "returns a 422 and does not create the organization with invalid params" do
        expect do
          post api_admin_organizations_path, params: {}, headers: headers
        end.not_to change(Organization, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when updating an organization" do
      let!(:organization) { create(:organization, org_params) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "accepts request and updates the organization with valid params" do
        expect do
          put api_admin_organization_path(organization.id), headers: headers, params: {
            organization: { summary: "new summary" }
          }
        end.to change(organization, :summary).to("new summary")

        expect(response).to have_http_status(:ok)
      end

      it "returns a 422 and does not update the organization with invalid params" do
        expect do
          put api_admin_organization_path(organization.id),
              params: { organization: { name: "" } },
              headers: headers
        end.not_to change(organization, :name)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when deleting an organization" do
      let!(:organization) { create(:organization, org_params) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "accepts request and deletes the organization when found" do
        expect do
          delete api_admin_organization_path(organization.id), headers: headers
        end.to change(Organization, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it "errors when no organization is found" do
        expect do
          delete api_admin_organization_path(0), headers: headers
        end.not_to change(Organization, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
