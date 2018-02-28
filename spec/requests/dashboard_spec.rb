require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  describe "GET /dashboard" do
    context "when logged-in" do
      before do
        article
        login_as user
      end

      it "renders user's articles" do
        get "/dashboard"
        expect(response.body).to include CGI.escapeHTML(article.title)
      end

      it "renders user's organization articles" do
        organization = create(:organization)
        user.update(organization_id: organization.id, org_admin: true)
        article.update(organization_id: organization.id)
        get "/dashboard/organization"
        expect(response.body).to include CGI.escapeHTML(organization.name.upcase)
      end
    end

    it "redirects to /enter if no current_user" do
      get "/dashboard/organization"
      expect(response.body).to redirect_to("/enter")
    end
  end
end
