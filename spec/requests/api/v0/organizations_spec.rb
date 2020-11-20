require "rails_helper"

RSpec.describe "Api::V0::Organizations", type: :request do
  describe "GET /api/organizations/:username" do
    let(:organization) { create(:organization) }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username"
      expect(response).to have_http_status(:not_found)
    end

    it "returns the correct json representation of the organization", :aggregate_failures do
      get "/api/organizations/#{organization.username}"

      response_organization = response.parsed_body

      expect(response_organization["type_of"]).to eq("organization")

      %w[
        username name summary twitter_username github_username url location tech_stack tag_line story
      ].each do |attr|
        expect(response_organization[attr]).to eq(organization.public_send(attr))
      end

      expect(response_organization["joined_at"]).to eq(organization.created_at.utc.iso8601)
    end
  end

  describe "GET /api/organizations/:username/users" do
    let!(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username/users"
      expect(response).to have_http_status(:not_found)
    end

    it "supports pagination" do
      create(:organization_membership, user: create(:user), organization: organization)

      get "/api/organizations/#{organization.username}/users", params: { page: 1, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get "/api/organizations/#{organization.username}/users", params: { page: 2, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get "/api/organizations/#{organization.username}/users", params: { page: 3, per_page: 1 }
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations users", :aggregate_failures do
      get "/api/organizations/#{organization.username}/users"

      response_org_users = response.parsed_body

      %w[
        username name twitter_username github_username website_url
      ].each do |attr|
        expect(response_org_users.first[attr]).to eq(org_user.public_send(attr))
      end

      expect(response_org_users.first["profile_image_url"]).to eq(org_user["profile_image_url"])
    end
  end
end
