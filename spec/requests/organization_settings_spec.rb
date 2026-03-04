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

    it "updates page_markdown" do
      patch "/#{organization.slug}/settings", params: {
        organization: { page_markdown: "# Welcome to our org" }
      }
      expect(response).to redirect_to(organization_settings_path(organization.slug))
      expect(organization.reload.page_markdown).to eq("# Welcome to our org")
    end

    it "processes page_markdown into HTML" do
      patch "/#{organization.slug}/settings", params: {
        organization: { page_markdown: "**bold**" }
      }
      expect(organization.reload.processed_page_html).to include("<strong>bold</strong>")
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
            organization: { page_markdown: "# Hello" }
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
