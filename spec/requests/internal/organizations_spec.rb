require "rails_helper"

RSpec.describe "internal/organizations", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { Organization.first }

  before do
    create_list :organization, 5
    sign_in(admin)
  end

  describe "GETS /internal/organizations" do
    let(:organizations) { Organization.all.map { |o| CGI.escapeHTML(o.name) } }
    let(:another_organization) { create(:organization, name: "T-800") }

    it "lists all organizations" do
      get "/internal/organizations"
      expect(response.body).to include(*organizations)
    end

    it "allows searching" do
      get "/internal/organizations?search=#{organization.name}"
      expect(response.body).to include(organization.name)
      expect(response.body).not_to include(another_organization.name)
    end
  end

  describe "GET /internal/orgnaizations/:id" do
    it "renders the correct organization" do
      get "/internal/organizations/#{organization.id}"
      expect(response.body).to include(organization.name)
    end
  end
end
