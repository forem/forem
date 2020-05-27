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
      xit "redirects to /enter" do
        get "/dashboard"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      before do
        sign_in user
        article
      end

      xit "renders user's articles" do
        get "/dashboard"
        expect(response.body).to include(CGI.escapeHTML(article.title))
      end

      xit 'does not show "STATS" for articles' do
        get "/dashboard"
        expect(response.body).not_to include("STATS")
      end

      xit "renders the delete button for drafts" do
        unpublished_article
        get "/dashboard"
        expect(response.body).to include "DELETE"
      end
    end

    context "when logged in as a super admin" do
      xit "renders the specified user's articles" do
        article
        user
        sign_in super_admin
        get "/dashboard/#{user.username}"
        expect(response.body).to include(CGI.escapeHTML(article.title))
      end
    end

    context "when logged in as a pro user" do
      xit 'shows "STATS" for articles' do
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
      xit "redirects to /enter" do
        get "/dashboard/organization"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      xit "renders user's organization articles" do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        article.update(organization_id: organization.id)
        sign_in user
        get "/dashboard/organization/#{organization.id}"
        expect(response.body).to include "dashboard-collection-org-details"
      end

      xit "does not render the delete button for other org member's drafts" do
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
      xit "redirects to /enter" do
        get "/dashboard/following"
        expect(response).to redirect_to("/enter")
      end
    end

    describe "followed users section" do
      before do
        sign_in user
        user.follow second_user
        user.reload
        get "/dashboard/following_users"
      end

      xit "renders followed users count" do
        expect(response.body).to include "users (1)"
      end

      xit "lists followed users" do
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
    end

    describe "followed tags section" do
      let(:tag) { create(:tag) }

      before do
        sign_in user
        user.follow tag
        user.reload
        get "/dashboard/following_tags"
      end

      xit "renders followed tags count" do
        expect(response.body).to include "tags (1)"
      end

      xit "lists followed tags" do
        expect(response.body).to include tag.name
      end
    end

    describe "followed organizations section" do
      let(:organization) { create(:organization) }

      before do
        sign_in user
        user.follow organization
        user.reload
        get "/dashboard/following_organizations"
      end

      xit "renders followed organizations count" do
        expect(response.body).to include "organizations (1)"
      end

      xit "lists followed organizations" do
        expect(response.body).to include CGI.escapeHTML(organization.name)
      end
    end

    describe "followed podcasts section" do
      let(:podcast) { create(:podcast) }

      before do
        sign_in user
        user.follow podcast
        user.reload
        get "/dashboard/following_podcasts"
      end

      xit "renders followed podcast count" do
        expect(response.body).to include "podcasts (1)"
      end

      xit "lists followed podcasts" do
        expect(response.body).to include podcast.name
      end
    end
  end

  describe "GET /dashboard/user_followers" do
    context "when not logged in" do
      xit "redirects to /enter" do
        get "/dashboard/user_followers"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      xit "renders the current user's followers" do
        second_user.follow user
        sign_in user
        get "/dashboard/user_followers"
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
    end
  end

  describe "GET /dashboard/pro" do
    context "when not logged in" do
      xit "raises unauthorized" do
        get "/dashboard/pro"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when user does not have permission" do
      xit "raises unauthorized" do
        sign_in user
        expect { get "/dashboard/pro" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user has pro permission" do
      xit "shows page properly" do
        user.add_role(:pro)
        sign_in user
        get "/dashboard/pro"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org admin" do
      xit "shows page properly" do
        org = create :organization
        create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        user.add_role(:pro)
        login_as user
        get "/dashboard/pro/org/#{org.id}"
        expect(response.body).to include("pro")
      end
    end

    context "when user has pro permission and is an org member" do
      xit "shows page properly" do
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
