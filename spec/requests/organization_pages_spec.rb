require "rails_helper"

RSpec.describe "Organization Pages Controller Backend Protection" do
  let(:admin_user) { create(:user, :org_admin) }
  let(:organization) { admin_user.organizations.first }

  before do
    sign_in admin_user
  end

  describe "GET /:slug/settings/pages" do
    context "when feature flag is disabled" do
      before { FeatureFlag.disable(:org_readme) }

      it "returns 404 Not Found" do
        expect do
          get organization_pages_path(organization.slug)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when feature flag is enabled" do
      before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

      it "returns 200 OK" do
        get organization_pages_path(organization.slug)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /:slug/settings/pages" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    context "when creating the first page" do
      it "automatically creates the readme Showcase page" do
        expect {
          post organization_pages_path(organization.slug), params: {
            page: { title: "Welcome", body_markdown: "# Hello showcase" }
          }
        }.to change(Page, :count).by(1)

        page = organization.pages.last
        expect(page.slug).to eq("#{organization.slug}/readme")
        expect(page.title).to eq("Welcome")
      end
    end

    context "when creating subsequent pages" do
      before do
        # Create first page
        create(:page, organization: organization, slug: "#{organization.slug}/readme", template: "full_within_layout")
      end

      it "creates a custom page with a slug suffix" do
        expect {
          post organization_pages_path(organization.slug), params: {
            page: { title: "About Us", body_markdown: "# Custom about page", slug_suffix: "about" }
          }
        }.to change(Page, :count).by(1)

        page = organization.pages.last
        expect(page.slug).to eq("#{organization.slug}/about")
      end
    end
  end

  describe "PATCH /:slug/settings/pages/:id" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    let!(:readme_page) { create(:page, organization: organization, slug: "#{organization.slug}/readme", template: "full_within_layout") }

    it "updates details and prevents readme slug suffix change" do
      patch update_organization_page_path(organization.slug, readme_page), params: {
        page: { title: "Updated Showcase Title", slug_suffix: "something-else" }
      }
      expect(readme_page.reload.title).to eq("Updated Showcase Title")
      expect(readme_page.slug).to eq("#{organization.slug}/readme")
    end
  end

  describe "DELETE /:slug/settings/pages/:id" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    let!(:readme_page) { create(:page, organization: organization, slug: "#{organization.slug}/readme", template: "full_within_layout") }

    it "deletes the page" do
      expect {
        delete organization_page_path(organization.slug, readme_page)
      }.to change(Page, :count).by(-1)
    end
  end

  describe "POST /:slug/settings/pages/preview" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    it "renders the markdown preview" do
      post organization_pages_preview_path(organization.slug), params: { body_markdown: "**bold text**" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["processed_html"]).to include("<strong>bold text</strong>")
    end
  end
end
