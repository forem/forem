require "rails_helper"

RSpec.describe "OrganizationSettings" do
  let(:user) { create(:user, :org_admin) }
  let(:organization) { user.organizations.first }

  describe "GET /:slug/settings" do
    context "when signed in as org admin" do
      before { sign_in user }

      it "renders the settings page" do
        get "/#{organization.slug}/settings"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Page")
      end
    end

    context "when signed in as non-admin member" do
      let(:member) { create(:user) }

      before do
        create(:organization_membership, organization: organization, user: member, type_of_user: "member")
        sign_in member
      end

      it "denies access" do
        expect do
          get "/#{organization.slug}/settings"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get "/#{organization.slug}/settings"
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "PATCH /:slug/settings" do
    before { sign_in user }

    it "creates a Page record when submitting page_markdown" do
      expect {
        patch "/#{organization.slug}/settings", params: {
          organization: { page_markdown: "# Welcome to our org" }
        }
      }.to change(Page, :count).by(1)

      page = organization.pages.first
      expect(page.body_markdown).to eq("# Welcome to our org")
      expect(page.title).to eq(organization.name)
    end

    it "processes page_markdown into HTML via Page record" do
      patch "/#{organization.slug}/settings", params: {
        organization: { page_markdown: "**bold**" }
      }
      page = organization.pages.first
      expect(page.processed_html).to include("<strong>bold</strong>")
    end

    it "updates existing Page record on subsequent edits" do
      patch "/#{organization.slug}/settings", params: {
        organization: { page_markdown: "# First" }
      }
      expect {
        patch "/#{organization.slug}/settings", params: {
          organization: { page_markdown: "# Updated" }
        }
      }.not_to change(Page, :count)
      expect(organization.pages.first.body_markdown).to eq("# Updated")
    end

    it "destroys Page record when page_markdown is cleared" do
      patch "/#{organization.slug}/settings", params: {
        organization: { page_markdown: "# Hello" }
      }
      expect {
        patch "/#{organization.slug}/settings", params: {
          organization: { page_markdown: "" }
        }
      }.to change(Page, :count).by(-1)
    end

    it "updates organization profile fields" do
      patch "/#{organization.slug}/settings", params: {
        organization: { name: "New Org Name" }
      }
      expect(organization.reload.name).to eq("New Org Name")
    end

    context "when non-admin" do
      let(:member) { create(:user) }

      before do
        create(:organization_membership, organization: organization, user: member, type_of_user: "member")
        sign_in member
      end

      it "denies access" do
        expect do
          patch "/#{organization.slug}/settings", params: {
            organization: { name: "Hacked Name" }
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
