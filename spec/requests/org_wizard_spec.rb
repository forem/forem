require "rails_helper"

RSpec.describe "OrgWizard" do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user) }
  let(:non_admin) { create(:user) }

  before do
    create(:organization_membership, user: admin, organization: organization, type_of_user: "admin")
  end

  describe "POST /org-wizard/:slug/crawl" do
    before { sign_in admin }

    it "returns crawled data as JSON" do
      mock_page = double("MetaInspector",
                         best_title: "Test Org",
                         description: "A test",
                         best_url: "https://test.com",
                         images: double(best: nil),
                         meta: {},
                         meta_tags: { "name" => {} })
      allow(MetaInspector).to receive(:new).and_return(mock_page)
      allow(HTTParty).to receive(:get).and_return(double(body: "<html></html>", success?: true))

      post "/org-wizard/#{organization.slug}/crawl", params: { urls: ["https://test.com"] }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["title"]).to eq("Test Org")
    end

    context "when user is not an admin" do
      before { sign_in non_admin }

      it "raises authorization error" do
        expect {
          post "/org-wizard/#{organization.slug}/crawl", params: { urls: ["https://test.com"] }, as: :json
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /org-wizard/:slug/generate" do
    before do
      sign_in admin
      allow(Ai::Base).to receive(:new).and_return(double(call: "## Hello\n\nWelcome to our org."))
    end

    it "returns generated markdown and HTML" do
      post "/org-wizard/#{organization.slug}/generate",
           params: { org_data: { title: "Test", description: "Desc" }, dev_posts: [] },
           as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["markdown"]).to include("Hello")
      expect(json["html"]).to be_present
    end
  end

  describe "POST /org-wizard/:slug/iterate" do
    before do
      sign_in admin
      allow(Ai::Base).to receive(:new).and_return(double(call: "## Updated\n\nNew content."))
    end

    it "returns iterated markdown" do
      post "/org-wizard/#{organization.slug}/iterate",
           params: {
             current_markdown: "## Old",
             instruction: "Make it better",
             org_data: { title: "Test", description: "Desc" },
             dev_posts: []
           },
           as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["markdown"]).to include("Updated")
    end
  end

  describe "POST /org-wizard/:slug/save" do
    before { sign_in admin }

    it "saves markdown and color to organization" do
      post "/org-wizard/#{organization.slug}/save",
           params: { markdown: "## Test Page", detected_color: "#FF0000" },
           as: :json
      expect(response).to have_http_status(:ok)
      organization.reload
      expect(organization.page_markdown).to eq("## Test Page")
      expect(organization.bg_color_hex).to eq("#FF0000")
    end

    it "ignores invalid color format" do
      post "/org-wizard/#{organization.slug}/save",
           params: { markdown: "## Test", detected_color: "not-a-color" },
           as: :json
      expect(response).to have_http_status(:ok)
      organization.reload
      expect(organization.bg_color_hex).not_to eq("not-a-color")
    end
  end
end
