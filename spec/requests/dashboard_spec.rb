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
        sign_in user
        article
        get "/dashboard"
        expect(response.body).to include CGI.escapeHTML(article.title)
      end
    end

    context "when logged in as a super admin" do
      it "renders the specified user's articles" do
        article
        user
        sign_in super_admin
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
        sign_in user
        get "/dashboard/organization"
        expect(response.body).to include "#{CGI.escapeHTML(organization.name)} ("
      end
    end
  end

  describe "GET /dashboard/following" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/following"
        expect(response).to redirect_to("/enter")
      end
    end

    describe "followed users section" do
      before do
        sign_in user
        user.follow second_user
        user.reload
        get "/dashboard/following"
      end

      it "renders followed users count" do
        expect(response.body).to include "Followed users (1)"
      end

      it "lists followed users" do
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
    end

    describe "followed tags section" do
      let(:tag) { create(:tag) }

      before do
        sign_in user
        user.follow tag
        user.reload
        get "/dashboard/following"
      end

      it "renders followed tags count" do
        expect(response.body).to include "Followed tags (1)"
      end

      it "lists followed tags" do
        expect(response.body).to include tag.name
      end
    end

    describe "followed organizations section" do
      let(:organization) { create(:organization) }

      before do
        sign_in user
        user.follow organization
        user.reload
        get "/dashboard/following"
      end

      it "renders followed organizations count" do
        expect(response.body).to include "Followed organizations (1)"
      end

      it "lists followed organizations" do
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
        sign_in user
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
        sign_in user
        expect { get "/dashboard/pro" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user has pro permission" do
      it "shows page properly" do
        user.add_role(:pro)
        sign_in user
        get "/dashboard/pro"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org admin" do
      it "shows page properly" do
        org_admin.add_role(:pro)
        sign_in org_admin
        get "/dashboard/pro/org/#{org_admin.organization_id}"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org member" do
      it "shows page properly" do
        org = create :organization
        user.update(organization_id: org.id)
        user.add_role(:pro)
        sign_in user
        get "/dashboard/pro/org/#{org.id}"
        expect(response.body).to include("pro")
      end
    end
  end
end
