require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user)          { create(:user) }
  let(:second_user)   { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:article)       { create(:article, user: user) }
  let(:unpublished_article) { create(:article, user: user, published: false) }
  let(:organization) { create(:organization) }

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

      it 'shows "STATS" for articles' do
        article = create(:article, user: user)

        get "/dashboard"
        expect(response.body).to include("Stats")
        expect(response.body).to include("#{article.path}/stats")
      end

      it "renders the delete button for drafts" do
        unpublished_article
        get "/dashboard"
        expect(response.body).to include "Delete"
      end

      it "renders subscriptions for articles with subscriptions" do
        allow(user).to receive(:has_role?).and_call_original
        allow(user).to receive(:has_role?).with(:restricted_liquid_tag,
                                                LiquidTags::UserSubscriptionTag).and_return(true)
        article_with_user_subscription_tag = create(:article, user: user, with_user_subscription_tag: true)
        create(:user_subscription,
               subscriber_id: second_user.id,
               subscriber_email: second_user.email,
               author_id: article_with_user_subscription_tag.user_id,
               user_subscription_sourceable: article_with_user_subscription_tag)

        get "/dashboard"
        expect(response.body).to include "Subscriptions"
      end

      it "renders pagination if minimum amount of posts" do
        create_list(:article, 52, user: user)
        get "/dashboard"
        expect(response.body).to include "pagination"
      end

      it "does not render pagination if less than one full page" do
        create_list(:article, 3, user: user)
        get "/dashboard"
        expect(response.body).not_to include "pagination"
      end

      it "renders a link to analytics dashboard" do
        get dashboard_path

        expect(response.body).to include("Analytics")
      end

      it "renders a link to analytics for the org" do
        create(:organization_membership, type_of_user: :admin, organization: organization, user: user)

        get dashboard_path

        expect(response.body).to include(CGI.escapeHTML("Analytics for #{organization.name}"))
      end

      it "does not render a link to upload a video when enable_video_upload is false" do
        get dashboard_path
        allow(Settings::General).to receive(:enable_video_upload).and_return(false)

        expect(response.body).not_to include("Upload a video")
      end

      it "does not render a link to upload a video for a recent user" do
        get dashboard_path
        allow(Settings::General).to receive(:enable_video_upload).and_return(true)

        expect(response.body).not_to include("Upload a video")
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

    context "when logged in as a non recent user with enable_video_upload set to true on the Forem" do
      it "renders a link to upload a video" do
        Timecop.freeze(Time.current) do
          user.update!(created_at: 3.weeks.ago)
          allow(Settings::General).to receive(:enable_video_upload).and_return(true)

          sign_in user
          get dashboard_path

          expect(response.body).to include("Upload a video")
        end
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
        expect(response.body).to include "crayons-logo"
      end

      it "does not render the delete button for other org member's drafts" do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        create(:organization_membership, user: second_user, organization: organization, type_of_user: "admin")
        unpublished_article.update(organization_id: organization.id)
        sign_in second_user
        get "/dashboard/organization/#{organization.id}"
        expect(response.body).not_to include("Delete")
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
        get "/dashboard/following_users"
      end

      it "renders followed users count" do
        expect(response.body).to include "Following users (1)"
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
        get "/dashboard/following_tags"
      end

      it "renders followed tags count" do
        expect(response.body).to include "Following tags (1)"
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
        get "/dashboard/following_organizations"
      end

      it "renders followed organizations count" do
        expect(response.body).to include "Following organizations (1)"
      end

      it "lists followed organizations" do
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

      it "renders followed podcast count" do
        expect(response.body).to include "Following podcasts (1)"
      end

      it "lists followed podcasts" do
        expect(response.body).to include podcast.name
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

  describe "GET /dashboard/analytics" do
    context "when not logged in" do
      it "raises unauthorized" do
        get "/dashboard/analytics"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when user is signed in" do
      it "shows page properly" do
        sign_in user
        get "/dashboard/analytics"
        expect(response.body).to include("Analytics")
      end

      it "page always contain back to dashboard button" do
        sign_in user
        get "/dashboard/analytics"
        within "nav" do
          expect(page).to have_selector("a[href='/dashboard']")
        end
      end
    end

    context "when user is an org admin" do
      it "shows page properly" do
        org = create :organization
        create(:organization_membership, user: user, organization: org, type_of_user: "admin")

        sign_in user
        get "/dashboard/analytics/org/#{org.id}"
        expect(response.body).to include("Analytics")
      end
    end

    context "when user has is an org member" do
      it "shows page properly" do
        org = create :organization
        create(:organization_membership, user: user, organization: org)

        sign_in user
        get "/dashboard/analytics/org/#{org.id}"
        expect(response.body).to include("Analytics")
      end
    end
  end

  describe "GET /dashboard/subscriptions" do
    let(:author) { create(:user) }
    let(:article_with_user_subscription_tag) { create(:article, user: author, with_user_subscription_tag: true) }
    let(:params) do
      { source_type: article_with_user_subscription_tag.class.name, source_id: article_with_user_subscription_tag.id }
    end

    before do
      # Stub roles because adding them normally can cause flaky specs
      allow(author).to receive(:has_role?).and_call_original
      allow(author).to receive(:has_role?).with(:restricted_liquid_tag,
                                                LiquidTags::UserSubscriptionTag).and_return(true)

      sign_in author
    end

    it "renders subscriptions" do
      user_subscription = create(:user_subscription,
                                 subscriber_id: second_user.id,
                                 subscriber_email: second_user.email,
                                 author_id: article_with_user_subscription_tag.user_id,
                                 user_subscription_sourceable: article_with_user_subscription_tag)

      get "/dashboard/subscriptions", params: params
      expect(response.body).to include(user_subscription.subscriber_email)
    end

    it "displays a message if no subscriptions are found" do
      get "/dashboard/subscriptions", params: params
      expect(response.body).to include("You don't have any subscribers for this")
    end

    it "raises unauthorized when trying to access a source the user doesn't own" do
      unauthorized_article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
      create(:user_subscription,
             subscriber_id: second_user.id,
             subscriber_email: second_user.email,
             author_id: unauthorized_article.user_id,
             user_subscription_sourceable: unauthorized_article)
      unauthorized_article_params = { source_type: unauthorized_article.class.name, source_id: unauthorized_article.id }

      expect do
        get "/dashboard/subscriptions", params: unauthorized_article_params
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises an error for disallowed source_types" do
      invalid_source_type_params = { source_type: "Comment", source_id: 1 }
      expect do
        get "/dashboard/subscriptions", params: invalid_source_type_params
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error when the source can't be found" do
      nonexistant_article_params = { source_type: article.class.name, source_id: article.id + 999 }
      expect do
        get "/dashboard/subscriptions", params: nonexistant_article_params
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders pagination if minimum amount of subscriptions" do
      create_list(:user_subscription,
                  102, # Current pagination limit is 100
                  author: author,
                  user_subscription_sourceable: article_with_user_subscription_tag)
      get "/dashboard/subscriptions", params: params
      expect(response.body).to include "pagination"
    end

    it "does not render pagination if less than one full page" do
      create_list(:user_subscription,
                  5,
                  author: author,
                  user_subscription_sourceable: article_with_user_subscription_tag)
      get "/dashboard/subscriptions", params: params
      expect(response.body).not_to include "pagination"
    end
  end
end
