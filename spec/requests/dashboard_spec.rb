require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user)          { create(:user) }
  let(:second_user)   { create(:user) }
  let(:org_admin)     { create(:user, :org_admin) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:article)       { create(:article, user_id: user.id) }

  describe "GET /dashboard" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard"
        expect(response).to redirect_to("/enter")
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
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders user's organization articles" do
        user.update(organization_id: organization.id, org_admin: true)
        article.update(organization_id: organization.id)
        login_as user
        get "/dashboard/organization"
        expect(response.body).to include "#{CGI.escapeHTML(organization.name)} ("
      end
    end
  end

  describe "GET /dashboard/following_users" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/following_users"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      before { login_as user }

      it "renders users that current user follows" do
        user.follow second_user
        get "/dashboard/following_users"
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
      it "renders tags that current user follows" do
        tag = create(:tag)
        user.follow tag
        get "/dashboard/following_users"
        expect(response.body).to include CGI.escapeHTML(tag.name)
      end
      it "renders organizations that current user follows" do
        organization = create(:organization)
        user.follow organization
        get "/dashboard/following_users"
        expect(response.body).to include CGI.escapeHTML(organization.name)
      end
    end
  end

  describe "GET /dashboard/user_followers" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/user_followers"
        expect(response).to redirect_to("/enter")
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

  describe "GET /dashboard/pro" do
    context "when not logged in" do
      it "raises unauthorized" do
        get "/dashboard/pro"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when user does not have permission" do
      it "raises unauthorized" do
        login_as user
        expect { get "/dashboard/pro" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user has pro permission" do
      it "shows page properly" do
        user.add_role(:pro)
        login_as user
        get "/dashboard/pro"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org admin" do
      it "shows page properly" do
        org_admin.add_role(:pro)
        login_as org_admin
        get "/dashboard/pro/org/#{org_admin.organization_id}"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org member" do
      it "shows page properly" do
        org = create :organization
        user.update(organization_id: org.id)
        user.add_role(:pro)
        login_as user
        get "/dashboard/pro/org/#{org.id}"
        expect(response.body).to include("pro")
      end
    end
  end
end
