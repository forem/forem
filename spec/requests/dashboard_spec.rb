require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user)          { create(:user) }
  let(:second_user)   { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:article)       { create(:article, user_id: user.id) }

  describe "GET /dashboard" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard"
        is_expected.to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders user's articles" do
        login_as user
        article
        get "/dashboard"
        expect(response.body).to include CGI.escapeHTML(article.title)
      end
    end

    context "when logged in as a super admin" do
      it "renders the specified user's articles" do
        article
        user
        login_as super_admin
        get "/dashboard/#{user.username}"
        expect(response.body).to include CGI.escapeHTML(article.title)
      end
    end
  end

  describe "GET /dashboard/organization" do
    let(:organization) { create(:organization) }

    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/organization"
        is_expected.to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders user's organization articles" do
        user.update(organization_id: organization.id, org_admin: true)
        article.update(organization_id: organization.id)
        login_as user
        get "/dashboard/organization"
        expect(response.body).to include CGI.escapeHTML(organization.name.upcase)
      end
    end
  end

  describe "GET /dashboard/following_users" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/following_users"
        is_expected.to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders the current user's followings" do
        user.follow second_user
        login_as user
        get "/dashboard/following_users"
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
    end
  end

  describe "GET /dashboard/user_followers" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/user_followers"
        is_expected.to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders the current user's followers" do
        second_user.follow user
        login_as user
        get "/dashboard/user_followers"
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
    end
  end
end
