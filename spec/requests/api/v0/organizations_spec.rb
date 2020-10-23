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
end
