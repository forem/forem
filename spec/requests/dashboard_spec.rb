require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user)          { create(:user) }
  let(:second_user)   { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:pro_user)      { create(:user, :pro) }
  let(:article)       { create(:article, user: user) }
  let(:unpublished_article) { create(:article, user: user, published: false) }

  describe "GET /dashboard" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      before do
        sign_in user
        article
      end

      it "renders user's articles" do
        get "/dashboard"
        expect(response.body).to include(CGI.escapeHTML(article.title))
      end

      it 'does not show "STATS" for articles' do
        get "/dashboard"
        expect(response.body).not_to include("STATS")
      end

      it "renders the delete button for drafts" do
        unpublished_article
        get "/dashboard"
        expect(response.body).to include "DELETE"
      end
    end

    context "when logged in as a super admin" do
      it "renders the specified user's articles" do
        article
        user
        sign_in super_admin
        get "/dashboard/#{user.username}"
        expect(response.body).to include(CGI.escapeHTML(article.title))
      end
    end

    context "when logged in as a pro user" do
      it 'shows "STATS" for articles' do
        article = create(:article, user: pro_user)
        sign_in pro_user
        get "/dashboard"
        expect(response.body).to include("STATS")
        expect(response.body).to include("#{article.path}/stats")
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
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        article.update(organization_id: organization.id)
        sign_in user
        get "/dashboard/organization/#{organization.id}"
        expect(response.body).to include "dashboard-collection-org-details"
      end

      it "does not render the delete button for other org member's drafts" do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        create(:organization_membership, user: second_user, organization: organization, type_of_user: "admin")
        unpublished_article.update(organization_id: organization.id)
        sign_in second_user
        get "/dashboard/organization/#{organization.id}"
        expect(response.body).not_to include("DELETE")
        expect(response.body).to include(ERB::Util.html_escape(unpublished_article.title))
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
        org = create :organization
        create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        user.add_role(:pro)
        login_as user
        get "/dashboard/pro/org/#{org.id}"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org member" do
      it "shows page properly" do
        org = create :organization
        create(:organization_membership, user: user, organization: org)
        user.add_role(:pro)
        sign_in user
        get "/dashboard/pro/org/#{org.id}"
        expect(response.body).to include("pro")
      end
    end
  end
end
